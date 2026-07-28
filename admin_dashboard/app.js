import { initializeApp } from "https://www.gstatic.com/firebasejs/10.8.1/firebase-app.js";
import {
  getAuth,
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut,
} from "https://www.gstatic.com/firebasejs/10.8.1/firebase-auth.js";
import {
  getFirestore,
  collection,
  getDocs,
  addDoc,
  doc,
  getDoc,
  updateDoc,
  deleteField,
  serverTimestamp,
} from "https://www.gstatic.com/firebasejs/10.8.1/firebase-firestore.js";

const firebaseConfig = {
  apiKey: "AIzaSyD0gvbSI1v2omQ9kvE-w4SjVohlCHNxHEo",
  appId: "1:1020489811715:web:19162a69855b1565394b36",
  messagingSenderId: "1020489811715",
  projectId: "campus--plug",
  authDomain: "campus--plug.firebaseapp.com",
  storageBucket: "campus--plug.firebasestorage.app",
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

const GENERIC_LOGIN_ERROR =
  "Unable to sign in. Check your email and password, then try again.";
const ACCESS_DENIED_MESSAGE =
  "This account does not have admin access.";

const AUDIT_COLLECTION = "adminAuditLog";

const AuditAction = Object.freeze({
  VENDOR_SUSPENDED: "vendor_suspended",
  VENDOR_REACTIVATED: "vendor_reactivated",
  PRODUCT_REMOVED: "product_removed",
  PRODUCT_RESTORED: "product_restored",
});

const AuditTargetType = Object.freeze({
  VENDOR: "vendor",
  PRODUCT: "product",
});

const AUDIT_ACTION_LABELS = Object.freeze({
  [AuditAction.VENDOR_SUSPENDED]: "Vendor suspended",
  [AuditAction.VENDOR_REACTIVATED]: "Vendor reactivated",
  [AuditAction.PRODUCT_REMOVED]: "Product removed",
  [AuditAction.PRODUCT_RESTORED]: "Product restored",
});

let state = {
  isAdmin: false,
  adminEmail: "",
  vendors: [],
  products: [],
  auditLogs: [],
  recentChats: [],
  activeChatsCount: 0,
  authReady: false,
};

const elements = {
  loginOverlay: document.getElementById("login-overlay"),
  loginForm: document.getElementById("login-form"),
  loginError: document.getElementById("login-error"),
  loginSubmit: document.getElementById("login-submit"),
  accessDeniedOverlay: document.getElementById("access-denied-overlay"),
  accessDeniedMessage: document.getElementById("access-denied-message"),
  accessDeniedSignOut: document.getElementById("access-denied-signout"),
  appContainer: document.getElementById("app"),
  navLinks: document.querySelectorAll(".nav-links li"),
  views: document.querySelectorAll(".view"),
  logoutBtn: document.getElementById("logout-btn"),
  adminEmailLabel: document.getElementById("admin-email-label"),

  statVendors: document.getElementById("stat-total-vendors"),
  statActiveChats: document.getElementById("stat-active-chats"),
  statRecentActivity: document.getElementById("stat-recent-activity"),
  chatsTbody: document.getElementById("chats-tbody"),
  chatsLoading: document.getElementById("chats-loading"),

  vendorsTbody: document.getElementById("vendors-tbody"),
  vendorsLoading: document.getElementById("vendors-loading"),
  vendorSort: document.getElementById("vendor-sort"),
  globalSearch: document.getElementById("global-search"),

  productsTbody: document.getElementById("products-tbody"),
  productsLoading: document.getElementById("products-loading"),
  productCampusFilter: document.getElementById("product-campus-filter"),
  productStatusFilter: document.getElementById("product-status-filter"),

  auditTbody: document.getElementById("audit-tbody"),
  auditLoading: document.getElementById("audit-loading"),
  auditActionFilter: document.getElementById("audit-action-filter"),

  suspendModal: document.getElementById("suspend-modal"),
  suspendReason: document.getElementById("suspend-reason"),
  suspendConfirmBtn: document.getElementById("suspend-confirm-btn"),
  suspendCancelBtn: document.getElementById("suspend-cancel-btn"),
  suspendVendorName: document.getElementById("suspend-vendor-name"),

  removeProductModal: document.getElementById("remove-product-modal"),
  removeProductReason: document.getElementById("remove-product-reason"),
  removeProductConfirmBtn: document.getElementById("remove-product-confirm-btn"),
  removeProductCancelBtn: document.getElementById("remove-product-cancel-btn"),
  removeProductName: document.getElementById("remove-product-name"),
};

let pendingSuspendVendorId = null;
let pendingRemoveProductId = null;

function showLogin() {
  state.isAdmin = false;
  state.adminEmail = "";
  elements.appContainer.classList.add("hidden");
  elements.accessDeniedOverlay.classList.add("hidden");
  elements.accessDeniedOverlay.classList.remove("active");
  elements.loginOverlay.classList.remove("hidden");
  elements.loginOverlay.classList.add("active");
  clearDashboardData();
}

function showAccessDenied(message) {
  state.isAdmin = false;
  elements.appContainer.classList.add("hidden");
  elements.loginOverlay.classList.add("hidden");
  elements.loginOverlay.classList.remove("active");
  elements.accessDeniedMessage.textContent = message || ACCESS_DENIED_MESSAGE;
  elements.accessDeniedOverlay.classList.remove("hidden");
  elements.accessDeniedOverlay.classList.add("active");
  clearDashboardData();
}

function showDashboard(email) {
  state.isAdmin = true;
  state.adminEmail = email || "";
  if (elements.adminEmailLabel) {
    elements.adminEmailLabel.textContent = state.adminEmail || "Admin";
  }
  elements.loginOverlay.classList.remove("active");
  elements.loginOverlay.classList.add("hidden");
  elements.accessDeniedOverlay.classList.add("hidden");
  elements.accessDeniedOverlay.classList.remove("active");
  elements.appContainer.classList.remove("hidden");
}

function clearDashboardData() {
  state.vendors = [];
  state.products = [];
  state.auditLogs = [];
  state.recentChats = [];
  state.activeChatsCount = 0;
  if (elements.vendorsTbody) elements.vendorsTbody.innerHTML = "";
  if (elements.productsTbody) elements.productsTbody.innerHTML = "";
  if (elements.auditTbody) elements.auditTbody.innerHTML = "";
  if (elements.chatsTbody) elements.chatsTbody.innerHTML = "";
  if (elements.statVendors) elements.statVendors.textContent = "-";
  if (elements.statActiveChats) elements.statActiveChats.textContent = "-";
  if (elements.statRecentActivity) elements.statRecentActivity.textContent = "-";
}

function setLoginError(message) {
  elements.loginError.textContent = message;
  elements.loginError.classList.remove("hidden");
}

function clearLoginError() {
  elements.loginError.classList.add("hidden");
  elements.loginError.textContent = "";
}

async function fetchUserIsAdmin(uid) {
  const snap = await getDoc(doc(db, "users", uid));
  if (!snap.exists()) return false;
  return snap.data()?.isAdmin === true;
}

async function resolveSession(user) {
  if (!user) {
    showLogin();
    return;
  }

  try {
    const admin = await fetchUserIsAdmin(user.uid);
    if (!admin) {
      showAccessDenied(ACCESS_DENIED_MESSAGE);
      return;
    }
    showDashboard(user.email || "");
    await initDashboard();
  } catch (error) {
    console.error("Failed to verify admin access:", error);
    showAccessDenied(
      "Could not verify admin access. Try again or contact support."
    );
  }
}

onAuthStateChanged(auth, async (user) => {
  state.authReady = true;
  await resolveSession(user);
});

elements.loginForm.addEventListener("submit", async (e) => {
  e.preventDefault();
  clearLoginError();

  const email = document.getElementById("admin-email").value.trim();
  const password = document.getElementById("admin-password").value;

  if (!email || !password) {
    setLoginError(GENERIC_LOGIN_ERROR);
    return;
  }

  elements.loginSubmit.disabled = true;
  try {
    await signInWithEmailAndPassword(auth, email, password);
    // onAuthStateChanged handles admin check + UI.
  } catch (error) {
    console.error("Admin login failed:", error);
    setLoginError(GENERIC_LOGIN_ERROR);
  } finally {
    elements.loginSubmit.disabled = false;
  }
});

async function handleSignOut() {
  clearLoginError();
  document.getElementById("admin-email").value = "";
  document.getElementById("admin-password").value = "";
  try {
    await signOut(auth);
  } catch (error) {
    console.error("Sign out failed:", error);
    showLogin();
  }
}

elements.logoutBtn.addEventListener("click", handleSignOut);
elements.accessDeniedSignOut.addEventListener("click", handleSignOut);

elements.navLinks.forEach((link) => {
  link.addEventListener("click", () => {
    if (!state.isAdmin) return;
    elements.navLinks.forEach((l) => l.classList.remove("active"));
    link.classList.add("active");
    const tabId = link.getAttribute("data-tab");
    elements.views.forEach((view) => view.classList.add("hidden"));
    document.getElementById(`view-${tabId}`).classList.remove("hidden");
  });
});

async function initDashboard() {
  if (!state.isAdmin) return;
  await fetchVendors();
  await fetchProducts();
  await fetchAuditLogs();
  await fetchRecentChats();
  renderStats();
}

async function fetchVendors() {
  if (!state.isAdmin) return;
  elements.vendorsLoading.classList.add("active");
  try {
    const vendorsSnapshot = await getDocs(collection(db, "vendors"));
    state.vendors = vendorsSnapshot.docs.map((d) => ({
      id: d.id,
      ...d.data(),
    }));
    renderVendors();
  } catch (error) {
    console.error("Error fetching vendors: ", error);
  } finally {
    elements.vendorsLoading.classList.remove("active");
  }
}

async function fetchProducts() {
  if (!state.isAdmin) return;
  if (elements.productsLoading) elements.productsLoading.classList.add("active");
  try {
    const productsSnapshot = await getDocs(collection(db, "products"));
    state.products = productsSnapshot.docs.map((d) => ({
      id: d.id,
      ...d.data(),
    }));
    renderProducts();
  } catch (error) {
    console.error("Error fetching products: ", error);
  } finally {
    if (elements.productsLoading) {
      elements.productsLoading.classList.remove("active");
    }
  }
}

async function fetchAuditLogs() {
  if (!state.isAdmin) return;
  if (elements.auditLoading) elements.auditLoading.classList.add("active");
  try {
    const snapshot = await getDocs(collection(db, AUDIT_COLLECTION));
    state.auditLogs = snapshot.docs.map((d) => ({
      id: d.id,
      ...d.data(),
    }));
    renderAuditLogs();
  } catch (error) {
    console.error("Error fetching audit log:", error);
    state.auditLogs = [];
    renderAuditLogs();
  } finally {
    if (elements.auditLoading) {
      elements.auditLoading.classList.remove("active");
    }
  }
}

/**
 * Append-only audit entry after a successful moderation write.
 * Soft-fails so a logging error does not undo the primary action.
 */
async function writeAuditLogEntry({
  action,
  targetId,
  targetType,
  targetName = "",
  reason = "",
}) {
  const user = auth.currentUser;
  if (!user || !state.isAdmin) return;

  const entry = {
    action,
    targetId,
    targetType,
    targetName: targetName || "",
    performedBy: user.uid,
    performedByEmail: user.email || state.adminEmail || "",
    reason: reason || "",
    timestamp: serverTimestamp(),
  };

  try {
    const ref = await addDoc(collection(db, AUDIT_COLLECTION), entry);
    state.auditLogs.unshift({
      id: ref.id,
      ...entry,
      timestamp: { toDate: () => new Date(), toMillis: () => Date.now() },
    });
    renderAuditLogs();
  } catch (error) {
    console.error("Failed to write audit log entry:", error);
  }
}

async function fetchRecentChats() {
  if (!state.isAdmin) return;
  elements.chatsLoading.classList.add("active");
  try {
    const oneDayAgo = new Date();
    oneDayAgo.setDate(oneDayAgo.getDate() - 1);

    const allChatsSnapshot = await getDocs(collection(db, "chats"));
    const allChats = allChatsSnapshot.docs.map((d) => ({
      id: d.id,
      ...d.data(),
    }));

    state.activeChatsCount = allChats.filter((c) => c.status === "active").length;

    state.recentChats = allChats
      .filter((c) => c.createdAt && c.createdAt.toDate() > oneDayAgo)
      .sort((a, b) => b.createdAt.toDate() - a.createdAt.toDate());

    renderChats();
  } catch (error) {
    console.error("Error fetching chats: ", error);
    // Likely blocked by participant-only chat list rules for non-participant admins.
    state.recentChats = [];
    state.activeChatsCount = 0;
    renderChats();
  } finally {
    elements.chatsLoading.classList.remove("active");
  }
}

function renderStats() {
  elements.statVendors.textContent = state.vendors.length;
  elements.statActiveChats.textContent = state.activeChatsCount;
  elements.statRecentActivity.textContent = state.recentChats.length;
}

function renderVendors() {
  if (!state.isAdmin) return;
  const tbody = elements.vendorsTbody;
  tbody.innerHTML = "";

  const sortVal = elements.vendorSort.value;
  let sortedVendors = [...state.vendors];
  if (sortVal === "newest") {
    sortedVendors.sort(
      (a, b) => (b.createdAt?.toMillis() || 0) - (a.createdAt?.toMillis() || 0)
    );
  } else if (sortVal === "rating") {
    sortedVendors.sort(
      (a, b) => (b.ratingAverage || 0) - (a.ratingAverage || 0)
    );
  } else if (sortVal === "name") {
    sortedVendors.sort((a, b) =>
      (a.businessName || "").localeCompare(b.businessName || "")
    );
  }

  const search = elements.globalSearch.value.toLowerCase();
  if (search) {
    sortedVendors = sortedVendors.filter(
      (v) =>
        (v.businessName || "").toLowerCase().includes(search) ||
        (v.category || "").toLowerCase().includes(search)
    );
  }

  sortedVendors.forEach((vendor) => {
    const joinedDate = vendor.createdAt
      ? vendor.createdAt.toDate().toLocaleDateString()
      : "Unknown";
    const isVerified = vendor.isVerified || false;
    const status = vendor.status === "suspended" ? "suspended" : "active";
    const isSuspended = status === "suspended";
    const rating = vendor.ratingAverage
      ? vendor.ratingAverage.toFixed(1)
      : "0.0";

    const tr = document.createElement("tr");
    if (isSuspended) tr.classList.add("row-suspended");
    tr.innerHTML = `
      <td>
        <div class="vendor-cell">
          <img src="${vendor.logoUrl || "https://via.placeholder.com/40"}" alt="${vendor.businessName || "Vendor"}">
          <div>
            <strong>${vendor.businessName || "Unnamed"}</strong>
            <div style="font-size: 0.8rem; color: var(--text-muted)">${vendor.campusId || "Unknown Campus"}</div>
          </div>
        </div>
      </td>
      <td>${vendor.category || (vendor.categories ? vendor.categories[0] : "N/A")}</td>
      <td>⭐ ${rating} <span style="font-size:0.8rem;color:var(--text-muted)">(${vendor.ratingCount || 0})</span></td>
      <td>${joinedDate}</td>
      <td>
        <span class="badge ${isVerified ? "badge-verified" : "badge-unverified"}">
          ${isVerified ? "Verified" : "Unverified"}
        </span>
        <span class="badge ${isSuspended ? "badge-suspended" : "badge-active"}" style="margin-left:6px">
          ${isSuspended ? "Suspended" : "Active"}
        </span>
      </td>
      <td>
        <div class="action-stack">
          <button class="btn btn-small ${isVerified ? "btn-danger" : "btn-success"}" data-id="${vendor.id}" data-action="toggle-verify">
            ${isVerified ? "Revoke" : "Verify"}
          </button>
          <button class="btn btn-small ${isSuspended ? "btn-success" : "btn-warning"}" data-id="${vendor.id}" data-action="toggle-suspend">
            ${isSuspended ? "Reactivate" : "Suspend"}
          </button>
        </div>
      </td>
    `;
    tbody.appendChild(tr);
  });

  document.querySelectorAll('button[data-action="toggle-verify"]').forEach((btn) => {
    btn.addEventListener("click", async (e) => {
      if (!state.isAdmin) return;
      const vendorId = e.currentTarget.getAttribute("data-id");
      await toggleVendorVerification(vendorId);
    });
  });

  document.querySelectorAll('button[data-action="toggle-suspend"]').forEach((btn) => {
    btn.addEventListener("click", async (e) => {
      if (!state.isAdmin) return;
      const vendorId = e.currentTarget.getAttribute("data-id");
      await handleSuspendClick(vendorId);
    });
  });
}

function renderChats() {
  if (!state.isAdmin) return;
  const tbody = elements.chatsTbody;
  tbody.innerHTML = "";

  if (state.recentChats.length === 0) {
    tbody.innerHTML =
      '<tr><td colspan="5" style="text-align:center;color:var(--text-muted)">No recent activity in the last 24h</td></tr>';
    return;
  }

  state.recentChats.forEach((chat) => {
    let vendorName = "Unknown Vendor";
    let buyerName = "Unknown Buyer";
    if (chat.participantNames) {
      const names = Object.values(chat.participantNames);
      if (names.length >= 2) {
        vendorName = names[0];
        buyerName = names[1];
      }
    }

    const timeString = chat.lastMessageTime
      ? chat.lastMessageTime.toDate().toLocaleTimeString([], {
          hour: "2-digit",
          minute: "2-digit",
        })
      : "Unknown";

    const tr = document.createElement("tr");
    tr.innerHTML = `
      <td><strong>${vendorName}</strong></td>
      <td>${buyerName}</td>
      <td>${chat.subject || "Order Inquiry"}</td>
      <td style="max-width: 200px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; color: var(--text-muted)">
        ${chat.lastMessage || "No messages yet"}
      </td>
      <td>${timeString}</td>
    `;
    tbody.appendChild(tr);
  });
}

async function toggleVendorVerification(vendorId) {
  if (!state.isAdmin) return;
  const vendorIndex = state.vendors.findIndex((v) => v.id === vendorId);
  if (vendorIndex === -1) return;

  // Re-check admin before write (session may have been revoked).
  const user = auth.currentUser;
  if (!user) {
    showLogin();
    return;
  }
  const stillAdmin = await fetchUserIsAdmin(user.uid);
  if (!stillAdmin) {
    showAccessDenied(ACCESS_DENIED_MESSAGE);
    return;
  }

  const currentStatus = state.vendors[vendorIndex].isVerified || false;
  const newStatus = !currentStatus;

  try {
    const vendorRef = doc(db, "vendors", vendorId);
    await updateDoc(vendorRef, { isVerified: newStatus });
    state.vendors[vendorIndex].isVerified = newStatus;
    renderVendors();
  } catch (error) {
    console.error("Error updating verification status:", error);
    alert("Failed to update status. Check permissions.");
  }
}

async function ensureAdminSession() {
  const user = auth.currentUser;
  if (!user) {
    showLogin();
    return false;
  }
  const stillAdmin = await fetchUserIsAdmin(user.uid);
  if (!stillAdmin) {
    showAccessDenied(ACCESS_DENIED_MESSAGE);
    return false;
  }
  return true;
}

function openSuspendModal(vendorId, vendorName) {
  pendingSuspendVendorId = vendorId;
  elements.suspendVendorName.textContent = vendorName || "this vendor";
  elements.suspendReason.value = "";
  elements.suspendModal.classList.remove("hidden");
}

function closeSuspendModal() {
  pendingSuspendVendorId = null;
  elements.suspendModal.classList.add("hidden");
  elements.suspendReason.value = "";
}

async function handleSuspendClick(vendorId) {
  if (!(await ensureAdminSession())) return;
  const vendor = state.vendors.find((v) => v.id === vendorId);
  if (!vendor) return;

  const isSuspended = vendor.status === "suspended";
  if (isSuspended) {
    await setVendorStatus(vendorId, "active");
    return;
  }
  openSuspendModal(vendorId, vendor.businessName);
}

async function setVendorStatus(vendorId, nextStatus, reason = "") {
  if (!(await ensureAdminSession())) return;
  const vendorIndex = state.vendors.findIndex((v) => v.id === vendorId);
  if (vendorIndex === -1) return;

  const vendor = state.vendors[vendorIndex];
  const vendorName = vendor.businessName || "";
  const vendorRef = doc(db, "vendors", vendorId);
  try {
    if (nextStatus === "suspended") {
      const trimmedReason = reason.trim() || "No reason provided";
      await updateDoc(vendorRef, {
        status: "suspended",
        suspensionReason: trimmedReason,
        suspendedAt: serverTimestamp(),
      });
      state.vendors[vendorIndex].status = "suspended";
      state.vendors[vendorIndex].suspensionReason = trimmedReason;
      await writeAuditLogEntry({
        action: AuditAction.VENDOR_SUSPENDED,
        targetId: vendorId,
        targetType: AuditTargetType.VENDOR,
        targetName: vendorName,
        reason: trimmedReason,
      });
    } else {
      await updateDoc(vendorRef, {
        status: "active",
        suspensionReason: deleteField(),
        suspendedAt: deleteField(),
      });
      state.vendors[vendorIndex].status = "active";
      delete state.vendors[vendorIndex].suspensionReason;
      delete state.vendors[vendorIndex].suspendedAt;
      await writeAuditLogEntry({
        action: AuditAction.VENDOR_REACTIVATED,
        targetId: vendorId,
        targetType: AuditTargetType.VENDOR,
        targetName: vendorName,
        reason: "",
      });
    }
    renderVendors();
  } catch (error) {
    console.error("Error updating vendor status:", error);
    alert("Failed to update vendor status. Check permissions.");
  }
}

elements.suspendCancelBtn.addEventListener("click", closeSuspendModal);
elements.suspendConfirmBtn.addEventListener("click", async () => {
  if (!pendingSuspendVendorId) return;
  const reason = elements.suspendReason.value.trim();
  if (!reason) {
    alert("Please enter a suspension reason.");
    return;
  }
  const id = pendingSuspendVendorId;
  closeSuspendModal();
  await setVendorStatus(id, "suspended", reason);
});

function campusLabel(campusId) {
  const map = {
    cu_miotso: "Miotso Campus",
    cu_accra: "Accra Campus",
    cu_tema: "Tema Campus",
  };
  return map[campusId] || campusId || "Unknown";
}

function productStatusBadge(status) {
  if (status === "removed") {
    return '<span class="badge badge-removed">Removed</span>';
  }
  if (status === "sold_out") {
    return '<span class="badge badge-sold-out">Sold out</span>';
  }
  return '<span class="badge badge-available">Available</span>';
}

function escapeHtml(text) {
  return String(text || "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function renderProducts() {
  if (!state.isAdmin || !elements.productsTbody) return;
  const tbody = elements.productsTbody;
  tbody.innerHTML = "";

  let list = [...state.products];
  list.sort(
    (a, b) => (b.createdAt?.toMillis?.() || 0) - (a.createdAt?.toMillis?.() || 0)
  );

  const campusFilter = elements.productCampusFilter?.value || "all";
  if (campusFilter !== "all") {
    list = list.filter((p) => p.campusId === campusFilter);
  }

  const statusFilter = elements.productStatusFilter?.value || "all";
  if (statusFilter !== "all") {
    list = list.filter((p) => (p.status || "available") === statusFilter);
  }

  const search = (elements.globalSearch?.value || "").toLowerCase();
  if (search) {
    list = list.filter(
      (p) =>
        (p.name || "").toLowerCase().includes(search) ||
        (p.vendorName || "").toLowerCase().includes(search) ||
        (p.campusId || "").toLowerCase().includes(search)
    );
  }

  if (list.length === 0) {
    tbody.innerHTML =
      '<tr><td colspan="6" style="text-align:center;color:var(--text-muted)">No products match these filters</td></tr>';
    return;
  }

  list.forEach((product) => {
    const status = product.status || "available";
    const isRemoved = status === "removed";
    const image =
      Array.isArray(product.imageUrls) && product.imageUrls[0]
        ? product.imageUrls[0]
        : "https://via.placeholder.com/40";
    const price =
      typeof product.price === "number"
        ? `GHS ${product.price.toFixed(2)}`
        : "—";
    const reasonNote =
      isRemoved && product.adminRemovalReason
        ? `<div style="font-size:0.75rem;color:var(--danger);margin-top:2px">${escapeHtml(
            product.adminRemovalReason
          )}</div>`
        : "";

    const tr = document.createElement("tr");
    if (isRemoved) tr.classList.add("row-removed");
    tr.innerHTML = `
      <td>
        <div class="product-cell">
          <img src="${image}" alt="">
          <div>
            <strong>${escapeHtml(product.name || "Unnamed")}</strong>
            ${reasonNote}
          </div>
        </div>
      </td>
      <td>${escapeHtml(product.vendorName || "Unknown")}</td>
      <td>${escapeHtml(campusLabel(product.campusId))}</td>
      <td>${price}</td>
      <td>${productStatusBadge(status)}</td>
      <td>
        <div class="action-stack">
          <button class="btn btn-small ${
            isRemoved ? "btn-success" : "btn-danger"
          }" data-id="${product.id}" data-action="toggle-remove-product">
            ${isRemoved ? "Restore" : "Remove"}
          </button>
        </div>
      </td>
    `;
    tbody.appendChild(tr);
  });

  document
    .querySelectorAll('button[data-action="toggle-remove-product"]')
    .forEach((btn) => {
      btn.addEventListener("click", async (e) => {
        if (!state.isAdmin) return;
        const productId = e.currentTarget.getAttribute("data-id");
        await handleRemoveProductClick(productId);
      });
    });
}

function openRemoveProductModal(productId, productName) {
  pendingRemoveProductId = productId;
  elements.removeProductName.textContent = productName || "this product";
  elements.removeProductReason.value = "";
  elements.removeProductModal.classList.remove("hidden");
}

function closeRemoveProductModal() {
  pendingRemoveProductId = null;
  elements.removeProductModal.classList.add("hidden");
  elements.removeProductReason.value = "";
}

async function handleRemoveProductClick(productId) {
  if (!(await ensureAdminSession())) return;
  const product = state.products.find((p) => p.id === productId);
  if (!product) return;

  if ((product.status || "available") === "removed") {
    await setProductModerationStatus(productId, "available");
    return;
  }
  openRemoveProductModal(productId, product.name);
}

async function setProductModerationStatus(productId, nextStatus, reason = "") {
  if (!(await ensureAdminSession())) return;
  const productIndex = state.products.findIndex((p) => p.id === productId);
  if (productIndex === -1) return;

  const product = state.products[productIndex];
  const productName = product.name || "";
  const productRef = doc(db, "products", productId);
  try {
    if (nextStatus === "removed") {
      const trimmedReason = reason.trim() || "No reason provided";
      await updateDoc(productRef, {
        status: "removed",
        adminRemovalReason: trimmedReason,
        adminRemovedAt: serverTimestamp(),
      });
      state.products[productIndex].status = "removed";
      state.products[productIndex].adminRemovalReason = trimmedReason;
      await writeAuditLogEntry({
        action: AuditAction.PRODUCT_REMOVED,
        targetId: productId,
        targetType: AuditTargetType.PRODUCT,
        targetName: productName,
        reason: trimmedReason,
      });
    } else {
      await updateDoc(productRef, {
        status: "available",
        adminRemovalReason: deleteField(),
        adminRemovedAt: deleteField(),
      });
      state.products[productIndex].status = "available";
      delete state.products[productIndex].adminRemovalReason;
      delete state.products[productIndex].adminRemovedAt;
      await writeAuditLogEntry({
        action: AuditAction.PRODUCT_RESTORED,
        targetId: productId,
        targetType: AuditTargetType.PRODUCT,
        targetName: productName,
        reason: "",
      });
    }
    renderProducts();
  } catch (error) {
    console.error("Error updating product moderation status:", error);
    alert("Failed to update product. Check permissions.");
  }
}

elements.removeProductCancelBtn?.addEventListener(
  "click",
  closeRemoveProductModal
);
elements.removeProductConfirmBtn?.addEventListener("click", async () => {
  if (!pendingRemoveProductId) return;
  const reason = elements.removeProductReason.value.trim();
  if (!reason) {
    alert("Please enter a removal reason.");
    return;
  }
  const id = pendingRemoveProductId;
  closeRemoveProductModal();
  await setProductModerationStatus(id, "removed", reason);
});

elements.globalSearch.addEventListener("input", () => {
  if (!state.isAdmin) return;
  renderVendors();
  renderProducts();
  renderAuditLogs();
});

elements.vendorSort.addEventListener("change", () => {
  if (!state.isAdmin) return;
  renderVendors();
});

elements.productCampusFilter?.addEventListener("change", () => {
  if (!state.isAdmin) return;
  renderProducts();
});

elements.productStatusFilter?.addEventListener("change", () => {
  if (!state.isAdmin) return;
  renderProducts();
});

function resolveAuditTargetName(entry) {
  if (entry.targetName) return entry.targetName;
  if (entry.targetType === AuditTargetType.VENDOR) {
    const vendor = state.vendors.find((v) => v.id === entry.targetId);
    return vendor?.businessName || entry.targetId || "Unknown vendor";
  }
  if (entry.targetType === AuditTargetType.PRODUCT) {
    const product = state.products.find((p) => p.id === entry.targetId);
    return product?.name || entry.targetId || "Unknown product";
  }
  return entry.targetId || "Unknown";
}

function formatAuditTimestamp(timestamp) {
  if (!timestamp) return "—";
  try {
    const date = typeof timestamp.toDate === "function" ? timestamp.toDate() : new Date(timestamp);
    return date.toLocaleString();
  } catch (_) {
    return "—";
  }
}

function renderAuditLogs() {
  if (!state.isAdmin || !elements.auditTbody) return;
  const tbody = elements.auditTbody;
  tbody.innerHTML = "";

  let list = [...state.auditLogs];
  list.sort(
    (a, b) =>
      (b.timestamp?.toMillis?.() || 0) - (a.timestamp?.toMillis?.() || 0)
  );

  const actionFilter = elements.auditActionFilter?.value || "all";
  if (actionFilter !== "all") {
    list = list.filter((e) => e.action === actionFilter);
  }

  const search = (elements.globalSearch?.value || "").toLowerCase();
  if (search) {
    list = list.filter((e) => {
      const targetName = resolveAuditTargetName(e).toLowerCase();
      return (
        (AUDIT_ACTION_LABELS[e.action] || e.action || "")
          .toLowerCase()
          .includes(search) ||
        targetName.includes(search) ||
        (e.performedByEmail || "").toLowerCase().includes(search) ||
        (e.reason || "").toLowerCase().includes(search)
      );
    });
  }

  if (list.length === 0) {
    tbody.innerHTML =
      '<tr><td colspan="5" style="text-align:center;color:var(--text-muted)">No audit entries yet</td></tr>';
    return;
  }

  list.forEach((entry) => {
    const actionLabel =
      AUDIT_ACTION_LABELS[entry.action] || entry.action || "Unknown";
    const targetName = resolveAuditTargetName(entry);
    const targetTypeLabel =
      entry.targetType === AuditTargetType.PRODUCT ? "Product" : "Vendor";
    const tr = document.createElement("tr");
    tr.innerHTML = `
      <td><strong>${escapeHtml(actionLabel)}</strong></td>
      <td>
        <div>
          <strong>${escapeHtml(targetName)}</strong>
          <div style="font-size:0.75rem;color:var(--text-muted)">${escapeHtml(
            targetTypeLabel
          )}</div>
        </div>
      </td>
      <td>${escapeHtml(entry.performedByEmail || entry.performedBy || "—")}</td>
      <td style="max-width:240px;color:var(--text-muted)">${escapeHtml(
        entry.reason || "—"
      )}</td>
      <td>${escapeHtml(formatAuditTimestamp(entry.timestamp))}</td>
    `;
    tbody.appendChild(tr);
  });
}

elements.auditActionFilter?.addEventListener("change", () => {
  if (!state.isAdmin) return;
  renderAuditLogs();
});
