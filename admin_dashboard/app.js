import { initializeApp } from "https://www.gstatic.com/firebasejs/10.8.1/firebase-app.js";
import { 
  getFirestore, 
  collection, 
  getDocs, 
  query, 
  where, 
  orderBy, 
  doc, 
  updateDoc,
  Timestamp 
} from "https://www.gstatic.com/firebasejs/10.8.1/firebase-firestore.js";

// Firebase Configuration
const firebaseConfig = {
  apiKey: 'AIzaSyD0gvbSI1v2omQ9kvE-w4SjVohlCHNxHEo',
  appId: '1:1020489811715:web:19162a69855b1565394b36',
  messagingSenderId: '1020489811715',
  projectId: 'campus--plug',
  authDomain: 'campus--plug.firebaseapp.com',
  storageBucket: 'campus--plug.firebasestorage.app',
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

// State
let state = {
  isAuthenticated: false,
  vendors: [],
  recentChats: [],
  activeChatsCount: 0
};

// DOM Elements
const elements = {
  loginOverlay: document.getElementById('login-overlay'),
  loginForm: document.getElementById('login-form'),
  loginError: document.getElementById('login-error'),
  appContainer: document.getElementById('app'),
  navLinks: document.querySelectorAll('.nav-links li'),
  views: document.querySelectorAll('.view'),
  logoutBtn: document.getElementById('logout-btn'),
  
  // Dashboard Elements
  statVendors: document.getElementById('stat-total-vendors'),
  statActiveChats: document.getElementById('stat-active-chats'),
  statRecentActivity: document.getElementById('stat-recent-activity'),
  chatsTbody: document.getElementById('chats-tbody'),
  chatsLoading: document.getElementById('chats-loading'),
  
  // Vendors Elements
  vendorsTbody: document.getElementById('vendors-tbody'),
  vendorsLoading: document.getElementById('vendors-loading'),
  vendorSort: document.getElementById('vendor-sort'),
  globalSearch: document.getElementById('global-search')
};

// --- AUTHENTICATION ---

elements.loginForm.addEventListener('submit', (e) => {
  e.preventDefault();
  const password = document.getElementById('admin-password').value;
  // Phase 0: Simple hardcoded check
  if (password === 'admin123') {
    state.isAuthenticated = true;
    elements.loginOverlay.classList.remove('active');
    setTimeout(() => {
      elements.loginOverlay.classList.add('hidden');
      elements.appContainer.classList.remove('hidden');
      initDashboard();
    }, 300);
  } else {
    elements.loginError.classList.remove('hidden');
  }
});

elements.logoutBtn.addEventListener('click', () => {
  state.isAuthenticated = false;
  elements.appContainer.classList.add('hidden');
  elements.loginOverlay.classList.remove('hidden');
  document.getElementById('admin-password').value = '';
  setTimeout(() => {
    elements.loginOverlay.classList.add('active');
  }, 10);
});

// --- NAVIGATION ---

elements.navLinks.forEach(link => {
  link.addEventListener('click', () => {
    // Update active nav state
    elements.navLinks.forEach(l => l.classList.remove('active'));
    link.classList.add('active');
    
    // Switch view
    const tabId = link.getAttribute('data-tab');
    elements.views.forEach(view => view.classList.add('hidden'));
    document.getElementById(`view-${tabId}`).classList.remove('hidden');
  });
});

// --- DATA FETCHING & RENDERING ---

async function initDashboard() {
  await fetchVendors();
  await fetchRecentChats();
  renderStats();
}

async function fetchVendors() {
  elements.vendorsLoading.classList.add('active');
  try {
    const vendorsSnapshot = await getDocs(collection(db, 'vendors'));
    state.vendors = vendorsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    renderVendors();
  } catch (error) {
    console.error("Error fetching vendors: ", error);
  } finally {
    elements.vendorsLoading.classList.remove('active');
  }
}

async function fetchRecentChats() {
  elements.chatsLoading.classList.add('active');
  try {
    const oneDayAgo = new Date();
    oneDayAgo.setDate(oneDayAgo.getDate() - 1);
    
    // Fetch active chats for stats
    const allChatsSnapshot = await getDocs(collection(db, 'chats'));
    const allChats = allChatsSnapshot.docs.map(doc => ({id: doc.id, ...doc.data()}));
    
    state.activeChatsCount = allChats.filter(c => c.status === 'active').length;
    
    // Filter recent chats locally since we already fetched them
    // (Firebase doesn't allow multiple inequality filters on different fields easily without composite indexes)
    state.recentChats = allChats
      .filter(c => c.createdAt && c.createdAt.toDate() > oneDayAgo)
      .sort((a, b) => b.createdAt.toDate() - a.createdAt.toDate());
      
    renderChats();
  } catch (error) {
    console.error("Error fetching chats: ", error);
  } finally {
    elements.chatsLoading.classList.remove('active');
  }
}

function renderStats() {
  elements.statVendors.textContent = state.vendors.length;
  elements.statActiveChats.textContent = state.activeChatsCount;
  elements.statRecentActivity.textContent = state.recentChats.length;
}

function renderVendors() {
  const tbody = elements.vendorsTbody;
  tbody.innerHTML = '';
  
  // Apply sorting
  const sortVal = elements.vendorSort.value;
  let sortedVendors = [...state.vendors];
  if (sortVal === 'newest') {
    sortedVendors.sort((a, b) => (b.createdAt?.toMillis() || 0) - (a.createdAt?.toMillis() || 0));
  } else if (sortVal === 'rating') {
    sortedVendors.sort((a, b) => (b.ratingAverage || 0) - (a.ratingAverage || 0));
  } else if (sortVal === 'name') {
    sortedVendors.sort((a, b) => (a.businessName || '').localeCompare(b.businessName || ''));
  }

  // Apply search
  const search = elements.globalSearch.value.toLowerCase();
  if (search) {
    sortedVendors = sortedVendors.filter(v => 
      (v.businessName || '').toLowerCase().includes(search) || 
      (v.category || '').toLowerCase().includes(search)
    );
  }

  sortedVendors.forEach(vendor => {
    const joinedDate = vendor.createdAt ? vendor.createdAt.toDate().toLocaleDateString() : 'Unknown';
    const isVerified = vendor.isVerified || false;
    const rating = vendor.ratingAverage ? vendor.ratingAverage.toFixed(1) : '0.0';
    
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td>
        <div class="vendor-cell">
          <img src="${vendor.logoUrl || 'https://via.placeholder.com/40'}" alt="${vendor.businessName}">
          <div>
            <strong>${vendor.businessName || 'Unnamed'}</strong>
            <div style="font-size: 0.8rem; color: var(--text-muted)">${vendor.campusId || 'Unknown Campus'}</div>
          </div>
        </div>
      </td>
      <td>${vendor.category || (vendor.categories ? vendor.categories[0] : 'N/A')}</td>
      <td>⭐ ${rating} <span style="font-size:0.8rem;color:var(--text-muted)">(${vendor.ratingCount || 0})</span></td>
      <td>${joinedDate}</td>
      <td>
        <span class="badge ${isVerified ? 'badge-verified' : 'badge-unverified'}">
          ${isVerified ? 'Verified' : 'Unverified'}
        </span>
      </td>
      <td>
        <button class="btn btn-small ${isVerified ? 'btn-danger' : 'btn-success'}" data-id="${vendor.id}" data-action="toggle-verify">
          ${isVerified ? 'Revoke' : 'Verify'}
        </button>
      </td>
    `;
    tbody.appendChild(tr);
  });

  // Attach event listeners for verify buttons
  document.querySelectorAll('button[data-action="toggle-verify"]').forEach(btn => {
    btn.addEventListener('click', async (e) => {
      const vendorId = e.currentTarget.getAttribute('data-id');
      await toggleVendorVerification(vendorId);
    });
  });
}

function renderChats() {
  const tbody = elements.chatsTbody;
  tbody.innerHTML = '';
  
  if (state.recentChats.length === 0) {
    tbody.innerHTML = '<tr><td colspan="5" style="text-align:center;color:var(--text-muted)">No recent activity in the last 24h</td></tr>';
    return;
  }

  state.recentChats.forEach(chat => {
    // Attempt to extract names
    let vendorName = 'Unknown Vendor';
    let buyerName = 'Unknown Buyer';
    if (chat.participantNames) {
      const names = Object.values(chat.participantNames);
      if (names.length >= 2) {
        vendorName = names[0];
        buyerName = names[1];
      }
    }

    const timeString = chat.lastMessageTime 
      ? chat.lastMessageTime.toDate().toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})
      : 'Unknown';

    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td><strong>${vendorName}</strong></td>
      <td>${buyerName}</td>
      <td>${chat.subject || 'Order Inquiry'}</td>
      <td style="max-width: 200px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; color: var(--text-muted)">
        ${chat.lastMessage || 'No messages yet'}
      </td>
      <td>${timeString}</td>
    `;
    tbody.appendChild(tr);
  });
}

async function toggleVendorVerification(vendorId) {
  const vendorIndex = state.vendors.findIndex(v => v.id === vendorId);
  if (vendorIndex === -1) return;
  
  const currentStatus = state.vendors[vendorIndex].isVerified || false;
  const newStatus = !currentStatus;
  
  try {
    const vendorRef = doc(db, 'vendors', vendorId);
    await updateDoc(vendorRef, { isVerified: newStatus });
    
    // Update local state and re-render
    state.vendors[vendorIndex].isVerified = newStatus;
    renderVendors();
  } catch (error) {
    console.error("Error updating verification status:", error);
    alert("Failed to update status. Check permissions.");
  }
}

// Global search listener
elements.globalSearch.addEventListener('input', () => {
  renderVendors();
});

// Sort listener
elements.vendorSort.addEventListener('change', () => {
  renderVendors();
});
