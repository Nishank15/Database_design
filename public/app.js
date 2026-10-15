/**
 * ============================================================================
 * ENTERPRISE HOSTEL MESS MANAGEMENT SYSTEM — PORTAL ENGINE
 * Course: B.Tech CSE • DBMS Project (Oracle PL/SQL • JDBC • ODBC)
 * Developer: NISHANK CHHIPA (Reg No: 25BCE1642)
 * ============================================================================
 */

// Application State
const STATE = {
  currentUser: null, // { role: 'ADMIN'|'STUDENT', displayName, username, studentId }
  currentView: 'turnstile',
  apiBase: 'http://localhost:8080/api',
  isBackendConnected: false,
  selectedPosStudentId: '25BCE1642',
  selectedPosDate: new Date().toISOString().split('T')[0],
  selectedPosCategory: 'CAT-BF',
  boarders: [],
  categories: [
    { categoryId: 'CAT-BF', categoryName: 'BREAKFAST', startTime: '07:30', endTime: '09:30', defaultRate: 50.00 },
    { categoryId: 'CAT-LN', categoryName: 'LUNCH', startTime: '12:30', endTime: '14:30', defaultRate: 90.00 },
    { categoryId: 'CAT-SN', categoryName: 'SNACKS', startTime: '17:00', endTime: '18:30', defaultRate: 35.00 },
    { categoryId: 'CAT-DN', categoryName: 'DINNER', startTime: '19:30', endTime: '21:30', defaultRate: 95.00 }
  ],
  swipes: [],
  rebates: [],
  bills: [],
  auditLogs: []
};

// Default Initial Seed (High-fidelity mirror of Oracle 3NF schema)
function getInitialSeed() {
  const today = new Date().toISOString().split('T')[0];
  const dMinus1 = new Date(Date.now() - 86400000).toISOString().split('T')[0];
  const dMinus2 = new Date(Date.now() - 86400000 * 2).toISOString().split('T')[0];
  const dPlus2 = new Date(Date.now() + 86400000 * 2).toISOString().split('T')[0];
  const dPlus3 = new Date(Date.now() + 86400000 * 3).toISOString().split('T')[0];
  const dPlus6 = new Date(Date.now() + 86400000 * 6).toISOString().split('T')[0];

  return {
    boarders: [
      { studentId: '25BCE1642', name: 'NISHANK CHHIPA', email: 'nishank.chhipa2025@vitstudent.ac.in', phone: '+91 94140 88219', blockId: 'BLK-B', roomNumber: '412', messType: 'NON_VEG', walletBalance: 3450.00, status: 'ACTIVE' },
      { studentId: '25BCE1001', name: 'Aarav Sharma', email: 'aarav.sharma2025@vitstudent.ac.in', phone: '+91 98765 43210', blockId: 'BLK-A', roomNumber: '104', messType: 'VEG', walletBalance: 1850.00, status: 'ACTIVE' },
      { studentId: '25BCE1089', name: 'Diya Iyer', email: 'diya.iyer2025@vitstudent.ac.in', phone: '+91 98112 34567', blockId: 'BLK-B', roomNumber: '205', messType: 'SPECIAL', walletBalance: 4200.00, status: 'ACTIVE' },
      { studentId: '25BCE1244', name: 'Rohan Verma', email: 'rohan.verma2025@vitstudent.ac.in', phone: '+91 97234 56789', blockId: 'BLK-C', roomNumber: '310', messType: 'NON_VEG', walletBalance: 520.00, status: 'ACTIVE' },
      { studentId: '25BCE1560', name: 'Ananya Patel', email: 'ananya.patel2025@vitstudent.ac.in', phone: '+91 96543 21098', blockId: 'BLK-D', roomNumber: '118', messType: 'VEG', walletBalance: 2900.00, status: 'ACTIVE' },
      { studentId: '25BCE1780', name: 'Kabir Reddy', email: 'kabir.reddy2025@vitstudent.ac.in', phone: '+91 95432 10987', blockId: 'BLK-A', roomNumber: '221', messType: 'SPECIAL', walletBalance: 150.00, status: 'ACTIVE' }
    ],
    rebates: [
      { rebateId: 1, studentId: '25BCE1001', studentName: 'Aarav Sharma', fromDate: '2026-09-25', toDate: '2026-09-28', reason: 'Inter-University Hackathon in Bengaluru', status: 'APPROVED', remarks: 'OD Certificate verified', appliedAt: '2026-09-24 10:15:00' },
      { rebateId: 2, studentId: '25BCE1244', studentName: 'Rohan Verma', fromDate: dMinus2, toDate: dPlus2, reason: 'Medical emergency leave with home warden intimation', status: 'APPROVED', remarks: 'Doctor prescription on file', appliedAt: '2026-10-08 14:20:00' },
      { rebateId: 3, studentId: '25BCE1642', studentName: 'NISHANK CHHIPA', fromDate: dPlus3, toDate: dPlus6, reason: 'Family function in Jaipur, Rajasthan', status: 'PENDING', remarks: 'Awaiting parent verification call', appliedAt: '2026-10-09 11:00:00' },
      { rebateId: 4, studentId: '25BCE1560', studentName: 'Ananya Patel', fromDate: '2026-09-20', toDate: '2026-09-24', reason: 'Conference symposium paper presentation', status: 'APPROVED', remarks: 'Academic OD granted', appliedAt: '2026-09-18 09:30:00' }
    ],
    swipes: [
      { swipeId: 101, studentId: '25BCE1642', categoryId: 'CAT-BF', swipeDate: dMinus1, swipeTime: '08:15:20', rateCharged: 50.00, turnstileId: 'TURNSTILE-GATE-01', status: 'ACCEPTED' },
      { swipeId: 102, studentId: '25BCE1642', categoryId: 'CAT-LN', swipeDate: dMinus1, swipeTime: '13:05:44', rateCharged: 90.00, turnstileId: 'TURNSTILE-GATE-01', status: 'ACCEPTED' },
      { swipeId: 103, studentId: '25BCE1642', categoryId: 'CAT-DN', swipeDate: dMinus1, swipeTime: '20:10:12', rateCharged: 95.00, turnstileId: 'TURNSTILE-GATE-02', status: 'ACCEPTED' },
      { swipeId: 104, studentId: '25BCE1089', categoryId: 'CAT-BF', swipeDate: today, swipeTime: '08:45:00', rateCharged: 50.00, turnstileId: 'TURNSTILE-GATE-01', status: 'ACCEPTED' }
    ],
    bills: [
      { billId: 1, studentId: '25BCE1642', studentName: 'NISHANK CHHIPA', month: 9, year: 2026, totalSwipes: 15, grossAmount: 1160.00, rebateDays: 3, rebateCredit: 540.00, netPayable: 620.00, paymentStatus: 'PAID', generatedAt: '2026-10-01 00:05:00' }
    ],
    auditLogs: [
      { logId: 501, actionType: 'SYSTEM_STARTUP', entityName: 'ORACLE_CORE', entityId: 'DB01', oldValue: null, newValue: 'Oracle 3NF Schema & Stored Procedure Engine Active', performedBy: 'NISHANK CHHIPA (25BCE1642)', timestamp: '2026-10-10 08:00:00' }
    ]
  };
}

// Initialize Local Store
function loadStateFromStorage() {
  const cached = localStorage.getItem('mess_portal_state_v2');
  if (cached) {
    try {
      const parsed = JSON.parse(cached);
      STATE.boarders = parsed.boarders || [];
      STATE.rebates = parsed.rebates || [];
      STATE.swipes = parsed.swipes || [];
      STATE.bills = parsed.bills || [];
      STATE.auditLogs = parsed.auditLogs || [];
      return;
    } catch (e) {
      console.warn('Storage parsing failed, resetting to initial seed.');
    }
  }
  const seed = getInitialSeed();
  STATE.boarders = seed.boarders;
  STATE.rebates = seed.rebates;
  STATE.swipes = seed.swipes;
  STATE.bills = seed.bills;
  STATE.auditLogs = seed.auditLogs;
  saveStateToStorage();
}

function saveStateToStorage() {
  localStorage.setItem('mess_portal_state_v2', JSON.stringify({
    boarders: STATE.boarders,
    rebates: STATE.rebates,
    swipes: STATE.swipes,
    bills: STATE.bills,
    auditLogs: STATE.auditLogs
  }));
}

// ----------------------------------------------------------------------------
// API & BACKEND SYNC
// ----------------------------------------------------------------------------
async function checkBackendConnection() {
  try {
    const res = await fetch(`${STATE.apiBase}/system/info`, { method: 'GET', signal: AbortSignal.timeout(1200) });
    if (res.ok) {
      const data = await res.json();
      STATE.isBackendConnected = true;
      document.getElementById('db-pill-text').textContent = data.oracleLive ? 'ORACLE JDBC LIVE' : 'JAVA SERVER SYNCED';
      document.getElementById('db-indicator-dot').style.backgroundColor = 'var(--color-pulse-green)';
      // Sync fresh data from backend
      await syncDataFromBackend();
      return;
    }
  } catch (err) {
    // Backend offline; run in full client-side Oracle PL/SQL Simulator mode
  }
  STATE.isBackendConnected = false;
  document.getElementById('db-pill-text').textContent = 'ORACLE ENGINE (SIM)';
  document.getElementById('db-indicator-dot').style.backgroundColor = 'var(--color-pulse-green)';
}

async function syncDataFromBackend() {
  if (!STATE.isBackendConnected) return;
  try {
    const [bRes, rRes, audRes] = await Promise.all([
      fetch(`${STATE.apiBase}/students`),
      fetch(`${STATE.apiBase}/rebates`),
      fetch(`${STATE.apiBase}/audit`)
    ]);
    if (bRes.ok) STATE.boarders = await bRes.json();
    if (rRes.ok) STATE.rebates = await rRes.json();
    if (audRes.ok) STATE.auditLogs = await audRes.json();
    saveStateToStorage();
  } catch (e) {
    console.warn('Sync failed:', e);
  }
}

// ----------------------------------------------------------------------------
// AUTHENTICATION & RBAC
// ----------------------------------------------------------------------------
function initAuthGateway() {
  const session = sessionStorage.getItem('mess_user_session');
  if (session) {
    try {
      STATE.currentUser = JSON.parse(session);
      applyUserSession();
      return;
    } catch (e) {}
  }
  // Default to Warden login modal view
  showAuthModal();
}

function showAuthModal() {
  document.getElementById('auth-modal').style.display = 'flex';
}

function hideAuthModal() {
  document.getElementById('auth-modal').style.display = 'none';
}

function applyUserSession() {
  hideAuthModal();
  const u = STATE.currentUser;
  document.getElementById('user-display-name').textContent = u.displayName || u.username;
  document.getElementById('user-role-label').textContent = u.role === 'ADMIN' ? 'MESS WARDEN' : `STUDENT (${u.studentId})`;
  document.getElementById('user-avatar-initial').textContent = (u.displayName || u.username).charAt(0).toUpperCase();

  // Navigation adjustments based on role
  if (u.role === 'STUDENT') {
    document.querySelectorAll('.admin-only-nav').forEach(el => el.style.display = 'none');
    document.getElementById('nav-student-portal').style.display = 'flex';
    navigateTo('student-portal');
  } else {
    document.querySelectorAll('.admin-only-nav').forEach(el => el.style.display = 'flex');
    document.getElementById('nav-student-portal').style.display = 'none';
    navigateTo('turnstile');
  }
}

function performLogin(username, password) {
  const errorEl = document.getElementById('auth-error-msg');
  errorEl.style.display = 'none';

  if (username === 'admin' && password === 'admin123') {
    STATE.currentUser = { role: 'ADMIN', username: 'admin', displayName: 'Chief Mess Warden' };
  } else if (username === 'warden_b' && password === 'warden123') {
    STATE.currentUser = { role: 'ADMIN', username: 'warden_b', displayName: 'Bhabha Hall Warden' };
  } else if (password === 'student123') {
    const boarder = STATE.boarders.find(b => b.studentId.toUpperCase() === username.toUpperCase());
    if (boarder) {
      STATE.currentUser = { role: 'STUDENT', username: boarder.studentId, displayName: boarder.name, studentId: boarder.studentId };
    } else {
      errorEl.textContent = `Student ID [${username}] not registered in boarder database.`;
      errorEl.style.display = 'block';
      return;
    }
  } else {
    errorEl.textContent = 'Invalid credentials. Please verify your password.';
    errorEl.style.display = 'block';
    return;
  }

  sessionStorage.setItem('mess_user_session', JSON.stringify(STATE.currentUser));
  applyUserSession();
}

function logout() {
  sessionStorage.removeItem('mess_user_session');
  STATE.currentUser = null;
  location.reload();
}

// ----------------------------------------------------------------------------
// VIEW NAVIGATION
// ----------------------------------------------------------------------------
function navigateTo(viewId) {
  STATE.currentView = viewId;
  document.querySelectorAll('.nav-item').forEach(el => {
    el.classList.toggle('active', el.dataset.view === viewId);
  });
  document.querySelectorAll('.view-section').forEach(el => {
    el.style.display = (el.id === `view-${viewId}`) ? 'block' : 'none';
  });

  // Breadcrumbs
  const viewTitles = {
    'turnstile': 'Turnstile POS Emulator',
    'boarders': 'Boarder Registry & Students',
    'rebates': 'Rebate Desk & Leave Approvals',
    'billing': 'Billing Engine (PL/SQL Cursor)',
    'audit': 'System Audit & Ledger Activity',
    'student-portal': 'Student Mess Portal'
  };
  document.getElementById('current-crumb-title').textContent = viewTitles[viewId] || 'Portal';

  // Render current view
  if (viewId === 'turnstile') renderTurnstileView();
  else if (viewId === 'boarders') renderBoardersView();
  else if (viewId === 'rebates') renderRebatesView();
  else if (viewId === 'billing') renderBillingView();
  else if (viewId === 'audit') renderAuditView();
  else if (viewId === 'student-portal') renderStudentPortalView();
}

// ----------------------------------------------------------------------------
// MODULE 1: TURNSTILE POS EMULATOR (ACCESS CONTROL & TRIGGER EXECUTION)
// ----------------------------------------------------------------------------
function renderTurnstileView() {
  const selectEl = document.getElementById('pos-student-select');
  selectEl.innerHTML = '';
  STATE.boarders.forEach(b => {
    const opt = document.createElement('option');
    opt.value = b.studentId;
    opt.textContent = `${b.studentId} — ${b.name} (${b.blockId}, Rm ${b.roomNumber})`;
    if (b.studentId === STATE.selectedPosStudentId) opt.selected = true;
    selectEl.appendChild(opt);
  });

  document.getElementById('pos-sim-date').value = STATE.selectedPosDate;
  updatePosStudentMeta();
}

function updatePosStudentMeta() {
  const sid = document.getElementById('pos-student-select').value;
  STATE.selectedPosStudentId = sid;
  STATE.selectedPosDate = document.getElementById('pos-sim-date').value;

  const b = STATE.boarders.find(x => x.studentId === sid);
  if (!b) return;

  document.getElementById('meta-block-room').textContent = `${b.blockId} • Room ${b.roomNumber}`;
  document.getElementById('meta-mess-plan').textContent = b.messType;
  document.getElementById('meta-wallet-balance').textContent = `₹${b.walletBalance.toLocaleString('en-IN', { minimumFractionDigits: 2 })}`;

  // Evaluate Active Rebate status for the selected simulation date
  const hasRebate = checkStudentRebateForDate(sid, STATE.selectedPosDate);
  const rebateTag = document.getElementById('meta-rebate-tag');
  if (hasRebate) {
    rebateTag.style.display = 'inline-flex';
    rebateTag.textContent = `ON REBATE LEAVE (${hasRebate.reason})`;
    rebateTag.className = 'badge badge-rejected';
  } else {
    rebateTag.style.display = 'none';
  }

  // Render 4 Slot Availability Cards
  renderPosSlotsGrid(sid, STATE.selectedPosDate);
}

function checkStudentRebateForDate(studentId, dateStr) {
  return STATE.rebates.find(r => {
    return r.studentId === studentId && r.status === 'APPROVED' && (dateStr >= r.fromDate && dateStr <= r.toDate);
  });
}

function renderPosSlotsGrid(studentId, dateStr) {
  const container = document.getElementById('pos-slots-grid');
  container.innerHTML = '';

  STATE.categories.forEach(cat => {
    // Check if swiped on this date
    const swiped = STATE.swipes.some(s => s.studentId === studentId && s.categoryId === cat.categoryId && s.swipeDate === dateStr && s.status === 'ACCEPTED');

    const card = document.createElement('div');
    card.className = `slot-card ${swiped ? 'swiped' : 'available'}`;
    card.dataset.categoryId = cat.categoryId;

    card.innerHTML = `
      <div class="slot-header">
        <span class="slot-name">${cat.categoryName}</span>
        <span class="badge ${swiped ? 'badge-swiped' : 'badge-available'}">${swiped ? 'SWIPED' : 'AVAILABLE'}</span>
      </div>
      <div class="slot-timing">${cat.startTime} – ${cat.endTime}</div>
      <div class="meta-row" style="margin-top: 6px;">
        <span class="meta-key">Tariff Rate</span>
        <span class="slot-rate">₹${cat.defaultRate.toFixed(2)}</span>
      </div>
      <button class="btn-primary" style="margin-top: 10px; width: 100%; ${swiped ? 'opacity: 0.5; cursor: not-allowed;' : ''}" onclick="executeTurnstileSwipe('${cat.categoryId}')" ${swiped ? 'disabled' : ''}>
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"></polyline></svg>
        ${swiped ? 'Already Swiped' : 'Swipe ' + cat.categoryName}
      </button>
    `;
    container.appendChild(card);
  });
}

// TURNSTILE SWIPE EXECUTION: Evaluates Oracle PL/SQL Triggers & Balance
async function executeTurnstileSwipe(categoryId) {
  const sid = STATE.selectedPosStudentId;
  const swipeDate = STATE.selectedPosDate;
  const banner = document.getElementById('pos-feedback-banner');
  const bannerText = document.getElementById('pos-banner-text');
  banner.className = 'pos-banner';

  const b = STATE.boarders.find(x => x.studentId === sid);
  const cat = STATE.categories.find(c => c.categoryId === categoryId);

  // Trigger 1 Check: trg_prevent_duplicate_swipe
  const isDuplicate = STATE.swipes.some(s => s.studentId === sid && s.categoryId === categoryId && s.swipeDate === swipeDate && s.status === 'ACCEPTED');
  if (isDuplicate) {
    banner.className = 'pos-banner pos-banner-error show';
    bannerText.innerHTML = `<strong>DUPLICATE SWIPE DENIED (-20001):</strong> Trigger <code>trg_prevent_duplicate_swipe</code> fired. Student <strong>${sid}</strong> already swiped for <strong>${cat.categoryName}</strong> on <strong>${swipeDate}</strong>.`;
    logAudit('SWIPE_DENIED', 'MEAL_SWIPES', sid, null, `Duplicate attempt on ${cat.categoryName} (${swipeDate})`, 'TURNSTILE_GATE_01');
    return;
  }

  // Trigger 2 Check: trg_rebate_swipe_guard
  const activeRebate = checkStudentRebateForDate(sid, swipeDate);
  if (activeRebate) {
    banner.className = 'pos-banner pos-banner-error show';
    bannerText.innerHTML = `<strong>REBATE POLICY VIOLATION (-20002):</strong> Trigger <code>trg_rebate_swipe_guard</code> fired. Student <strong>${sid}</strong> is on APPROVED mess leave from <code>${activeRebate.fromDate}</code> to <code>${activeRebate.toDate}</code>. Swiping during rebate absence is prohibited.`;
    logAudit('SWIPE_BLOCKED', 'MEAL_SWIPES', sid, null, `Rebate conflict: ${activeRebate.fromDate} to ${activeRebate.toDate}`, 'TURNSTILE_GATE_01');
    return;
  }

  // Minimum balance check
  if (b.walletBalance < cat.defaultRate) {
    banner.className = 'pos-banner pos-banner-error show';
    bannerText.innerHTML = `<strong>INSUFFICIENT BALANCE DENIAL:</strong> Current wallet balance <strong>₹${b.walletBalance.toFixed(2)}</strong> is lower than required tariff <strong>₹${cat.defaultRate.toFixed(2)}</strong>. Please recharge wallet.`;
    return;
  }

  // SUCCESSFUL EXECUTION
  const prevBal = b.walletBalance;
  b.walletBalance -= cat.defaultRate;

  const newSwipe = {
    swipeId: 100 + STATE.swipes.length + 1,
    studentId: sid,
    categoryId: categoryId,
    swipeDate: swipeDate,
    swipeTime: new Date().toLocaleTimeString('en-US', { hour12: false }),
    rateCharged: cat.defaultRate,
    turnstileId: 'TURNSTILE-GATE-01',
    status: 'ACCEPTED'
  };
  STATE.swipes.unshift(newSwipe);

  // Trigger 3 Audit: trg_audit_wallet_change
  logAudit('WALLET_BALANCE_UPDATE', 'STUDENTS', sid, `PREV=₹${prevBal.toFixed(2)}`, `NEW=₹${b.walletBalance.toFixed(2)}`, 'TURNSTILE_GATE_01');

  saveStateToStorage();
  updatePosStudentMeta();

  banner.className = 'pos-banner pos-banner-success show';
  bannerText.innerHTML = `<strong>ACCESS GRANTED:</strong> Turnstile unlocked for <strong>${b.name} (${sid})</strong>. <strong>${cat.categoryName}</strong> recorded. Tariff <strong>₹${cat.defaultRate.toFixed(2)}</strong> deducted. Updated balance: <strong>₹${b.walletBalance.toFixed(2)}</strong>.`;
}

// Reset today's swipes for clean viva walkthrough
function resetDemoSwipes() {
  const today = STATE.selectedPosDate;
  STATE.swipes = STATE.swipes.filter(s => s.swipeDate !== today);
  logAudit('DEMO_RESET', 'MEAL_SWIPES', 'ALL', null, `Cleared swipes for ${today}`, 'WARDEN_ADMIN');
  saveStateToStorage();
  updatePosStudentMeta();
  const banner = document.getElementById('pos-feedback-banner');
  banner.className = 'pos-banner pos-banner-success show';
  document.getElementById('pos-banner-text').innerHTML = `<strong>DEMO RESET APPLIED:</strong> All meal swipes for date <code>${today}</code> have been cleared for clean viva walkthrough testing.`;
}

// ----------------------------------------------------------------------------
// MODULE 2: BOARDER REGISTRY (STUDENT MANAGEMENT)
// ----------------------------------------------------------------------------
function renderBoardersView() {
  const search = (document.getElementById('boarder-search-input')?.value || '').toLowerCase();
  const messFilter = document.getElementById('boarder-mess-filter')?.value || 'ALL';

  const tbody = document.getElementById('boarders-table-body');
  tbody.innerHTML = '';

  const filtered = STATE.boarders.filter(b => {
    const matchesSearch = b.studentId.toLowerCase().includes(search) || b.name.toLowerCase().includes(search) || b.roomNumber.toLowerCase().includes(search) || b.blockId.toLowerCase().includes(search);
    const matchesMess = messFilter === 'ALL' || b.messType === messFilter;
    return matchesSearch && matchesMess;
  });

  filtered.forEach(b => {
    const isLow = b.walletBalance < 300;
    const isCritical = b.walletBalance < 100;
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td class="td-mono">${b.studentId}</td>
      <td><strong>${b.name}</strong><br><span style="font-size:11px;color:var(--color-fog)">${b.email}</span></td>
      <td>${b.blockId}</td>
      <td class="td-mono">${b.roomNumber}</td>
      <td><span class="badge ${b.messType === 'NON_VEG' ? 'badge-rejected' : b.messType === 'SPECIAL' ? 'badge-pending' : 'badge-available'}">${b.messType}</span></td>
      <td class="td-mono">₹${b.walletBalance.toLocaleString('en-IN', { minimumFractionDigits: 2 })}</td>
      <td><span class="badge ${isCritical ? 'badge-rejected' : isLow ? 'badge-pending' : 'badge-available'}">${isCritical ? 'CRITICAL' : isLow ? 'LOW FLOAT' : 'ACTIVE'}</span></td>
      <td>
        <div class="action-btn-group">
          <button class="btn-pill" style="color:var(--color-acid-lime);border-color:rgba(228,242,34,0.3)" onclick="openTopupModal('${b.studentId}')" title="Top-up wallet balance">+ Funds</button>
          <button class="btn-pill" onclick="openEditStudentModal('${b.studentId}')" title="Edit boarder profile">Edit</button>
          <button class="btn-pill btn-danger" onclick="openDeleteStudentModal('${b.studentId}')" title="Delete and deregister boarder">Delete</button>
          <button class="btn-pill" onclick="quickSelectStudentForPos('${b.studentId}')" title="Test turnstile swipe">POS</button>
        </div>
      </td>
    `;
    tbody.appendChild(tr);
  });
}

function quickSelectStudentForPos(studentId) {
  STATE.selectedPosStudentId = studentId;
  navigateTo('turnstile');
}

function openEnrollModal() {
  document.getElementById('enroll-modal').classList.add('open');
}

function closeEnrollModal() {
  document.getElementById('enroll-modal').classList.remove('open');
}

function handleEnrollSubmit(e) {
  e.preventDefault();
  const sid = document.getElementById('enroll-id').value.trim().toUpperCase();
  const name = document.getElementById('enroll-name').value.trim();
  const email = document.getElementById('enroll-email').value.trim();
  const phone = document.getElementById('enroll-phone').value.trim();
  const block = document.getElementById('enroll-block').value;
  const room = document.getElementById('enroll-room').value.trim();
  const mess = document.getElementById('enroll-mess').value;
  const bal = parseFloat(document.getElementById('enroll-balance').value) || 0;

  if (STATE.boarders.some(b => b.studentId === sid)) {
    alert(`Student ID [${sid}] already exists in boarder registry!`);
    return;
  }

  const newStudent = {
    studentId: sid,
    name: name,
    email: email,
    phone: phone,
    blockId: block,
    roomNumber: room,
    messType: mess,
    walletBalance: bal,
    status: 'ACTIVE'
  };

  STATE.boarders.unshift(newStudent);
  logAudit('STUDENT_ENROLLED', 'STUDENTS', sid, null, `Enrolled by warden into ${block} Rm ${room}`, 'WARDEN_ADMIN');
  saveStateToStorage();
  closeEnrollModal();
  renderBoardersView();
}

// ----------------------------------------------------------------------------
// MODAL HANDLERS: TOP-UP / ADD FUNDS (ADMIN)
// ----------------------------------------------------------------------------
function openTopupModal(studentId) {
  const b = STATE.boarders.find(x => x.studentId === studentId);
  if (!b) return;
  document.getElementById('topup-student-id').value = b.studentId;
  document.getElementById('topup-student-name').textContent = `${b.name} (${b.studentId})`;
  document.getElementById('topup-current-balance').textContent = `₹${b.walletBalance.toLocaleString('en-IN', { minimumFractionDigits: 2 })}`;
  document.getElementById('topup-amount').value = '';
  document.querySelectorAll('#topup-modal .chip-btn').forEach(c => c.classList.remove('active'));
  document.getElementById('topup-modal').classList.add('open');
}

function closeTopupModal() {
  document.getElementById('topup-modal').classList.remove('open');
}

function selectTopupChip(amount) {
  document.getElementById('topup-amount').value = amount;
  document.querySelectorAll('#topup-modal .chip-btn').forEach(c => {
    c.classList.toggle('active', c.textContent.includes(amount.toString()));
  });
}

async function handleTopupSubmit(e) {
  e.preventDefault();
  const sid = document.getElementById('topup-student-id').value;
  const amount = parseFloat(document.getElementById('topup-amount').value);
  if (!amount || amount <= 0) {
    alert('Please enter a valid deposit amount.');
    return;
  }

  // Attempt backend API call if online
  if (STATE.isBackendConnected) {
    try {
      const res = await fetch(`${STATE.apiBase}/students/add-funds`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ studentId: sid, amount: String(amount), source: 'ADMIN' })
      });
      if (res.ok) {
        const data = await res.json();
        const b = STATE.boarders.find(x => x.studentId === sid);
        if (b) b.walletBalance = data.newBalance;
      }
    } catch (err) {
      console.warn('Backend topup call failed, applying to local store:', err);
    }
  }

  const b = STATE.boarders.find(x => x.studentId === sid);
  if (b) {
    if (!STATE.isBackendConnected) {
      const prevBal = b.walletBalance;
      b.walletBalance += amount;
      logAudit('WALLET_TOP_UP', 'STUDENTS', sid, `PREV=₹${prevBal.toFixed(2)}`, `CREDIT=₹${amount.toFixed(2)}; NEW=₹${b.walletBalance.toFixed(2)}; SOURCE=ADMIN`, 'WARDEN_ADMIN');
    }
  }

  saveStateToStorage();
  closeTopupModal();
  renderBoardersView();
  if (STATE.currentView === 'turnstile') updatePosStudentMeta();
  alert(`Successfully credited ₹${amount.toFixed(2)} to ${b ? b.name : sid}. Updated balance: ₹${b ? b.walletBalance.toFixed(2) : ''}`);
}

// ----------------------------------------------------------------------------
// MODAL HANDLERS: EDIT STUDENT INFORMATION (ADMIN)
// ----------------------------------------------------------------------------
function openEditStudentModal(studentId) {
  const b = STATE.boarders.find(x => x.studentId === studentId);
  if (!b) return;
  document.getElementById('edit-student-id').value = b.studentId;
  document.getElementById('edit-student-name').value = b.name;
  document.getElementById('edit-student-block').value = b.blockId;
  document.getElementById('edit-student-room').value = b.roomNumber;
  document.getElementById('edit-student-mess').value = b.messType;
  document.getElementById('edit-student-status').value = b.status || 'ACTIVE';
  document.getElementById('edit-student-modal').classList.add('open');
}

function closeEditStudentModal() {
  document.getElementById('edit-student-modal').classList.remove('open');
}

async function handleEditStudentSubmit(e) {
  e.preventDefault();
  const sid = document.getElementById('edit-student-id').value;
  const name = document.getElementById('edit-student-name').value.trim();
  const block = document.getElementById('edit-student-block').value;
  const room = document.getElementById('edit-student-room').value.trim();
  const mess = document.getElementById('edit-student-mess').value;
  const status = document.getElementById('edit-student-status').value;

  if (STATE.isBackendConnected) {
    try {
      await fetch(`${STATE.apiBase}/students/update`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ studentId: sid, name, blockId: block, roomNumber: room, messType: mess, status })
      });
    } catch (err) {
      console.warn('Backend student update failed, updating local state:', err);
    }
  }

  const b = STATE.boarders.find(x => x.studentId === sid);
  if (b) {
    b.name = name;
    b.blockId = block;
    b.roomNumber = room;
    b.messType = mess;
    b.status = status;
    logAudit('STUDENT_UPDATED', 'STUDENTS', sid, null, `Name=${name}; Block=${block}; Room=${room}; Mess=${mess}; Status=${status}`, 'WARDEN_ADMIN');
  }

  saveStateToStorage();
  closeEditStudentModal();
  renderBoardersView();
  if (STATE.currentView === 'turnstile') renderTurnstileView();
  alert(`Student profile for [${name} (${sid})] updated successfully.`);
}

// ----------------------------------------------------------------------------
// MODAL HANDLERS: DELETE / DEREGISTER STUDENT (ADMIN)
// ----------------------------------------------------------------------------
function openDeleteStudentModal(studentId) {
  const b = STATE.boarders.find(x => x.studentId === studentId);
  if (!b) return;
  document.getElementById('delete-student-id').value = b.studentId;
  document.getElementById('delete-student-name').textContent = `${b.name} (${b.studentId})`;
  document.getElementById('delete-student-modal').classList.add('open');
}

function closeDeleteStudentModal() {
  document.getElementById('delete-student-modal').classList.remove('open');
}

async function handleDeleteStudentSubmit(e) {
  e.preventDefault();
  const sid = document.getElementById('delete-student-id').value;
  const b = STATE.boarders.find(x => x.studentId === sid);
  const sname = b ? b.name : sid;

  if (STATE.isBackendConnected) {
    try {
      await fetch(`${STATE.apiBase}/students/delete`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ studentId: sid })
      });
    } catch (err) {
      console.warn('Backend student delete failed, updating local state:', err);
    }
  }

  // Cascading cleanup in local state
  STATE.boarders = STATE.boarders.filter(x => x.studentId !== sid);
  STATE.swipes = STATE.swipes.filter(s => s.studentId !== sid);
  STATE.rebates = STATE.rebates.filter(r => r.studentId !== sid);
  STATE.bills = STATE.bills.filter(bll => bll.studentId !== sid);

  logAudit('STUDENT_DEREGISTERED', 'STUDENTS', sid, null, `Deregistered ${sname} with cascading cleanup`, 'WARDEN_ADMIN');
  saveStateToStorage();

  if (STATE.selectedPosStudentId === sid && STATE.boarders.length > 0) {
    STATE.selectedPosStudentId = STATE.boarders[0].studentId;
  }

  closeDeleteStudentModal();
  renderBoardersView();
  if (STATE.currentView === 'turnstile') renderTurnstileView();
  alert(`Boarder [${sname} (${sid})] has been permanently deregistered and deleted.`);
}
function renderRebatesView() {
  const tbody = document.getElementById('rebates-table-body');
  tbody.innerHTML = '';
  const today = new Date().toISOString().split('T')[0];

  STATE.rebates.forEach(r => {
    // Determine date awareness badge
    let dateBadge = '';
    if (r.status === 'APPROVED') {
      if (today >= r.fromDate && today <= r.toDate) {
        dateBadge = '<span class="badge badge-active-today">ACTIVE TODAY</span>';
      } else if (today < r.fromDate) {
        dateBadge = '<span class="badge badge-pending">SCHEDULED</span>';
      } else {
        dateBadge = '<span class="badge badge-expired">EXPIRED</span>';
      }
    }

    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td class="td-mono">#${r.rebateId}</td>
      <td><strong>${r.studentName || r.studentId}</strong><br><span class="td-mono" style="font-size:11px;color:var(--color-fog)">${r.studentId}</span></td>
      <td class="td-mono">${r.fromDate} &rarr; ${r.toDate}</td>
      <td>${r.reason}</td>
      <td>
        <span class="badge badge-${r.status.toLowerCase()}">${r.status}</span>
        ${dateBadge}
      </td>
      <td>
        ${r.status === 'PENDING' ? `
          <button class="btn-pill" style="color:var(--color-pulse-green);border-color:rgba(39,166,68,0.4)" onclick="processRebateAction(${r.rebateId}, 'APPROVE')">Approve</button>
          <button class="btn-pill" style="color:var(--color-coral-red);border-color:rgba(235,87,87,0.4)" onclick="processRebateAction(${r.rebateId}, 'REJECT')">Reject</button>
        ` : r.status === 'APPROVED' ? `
          <button class="btn-pill" style="color:var(--color-coral-red);border-color:rgba(235,87,87,0.4)" onclick="processRebateAction(${r.rebateId}, 'REVOKE')">Revoke</button>
        ` : `<span style="font-size:11px;color:var(--color-ash)">Finalized</span>`}
      </td>
    `;
    tbody.appendChild(tr);
  });
}

function processRebateAction(rebateId, action) {
  const r = STATE.rebates.find(x => x.rebateId === rebateId);
  if (!r) return;
  const oldStatus = r.status;
  r.status = action === 'APPROVE' ? 'APPROVED' : action === 'REJECT' ? 'REJECTED' : 'REVOKED';
  r.remarks = `Actioned as ${r.status} by Warden`;

  logAudit(`REBATE_${action}`, 'REBATE_REQUESTS', String(rebateId), oldStatus, r.status, 'WARDEN_ADMIN');
  saveStateToStorage();
  renderRebatesView();
  // Update Turnstile POS if viewing
  if (STATE.currentView === 'turnstile') updatePosStudentMeta();
}

function handleRebateSubmit(e) {
  e.preventDefault();
  const sid = document.getElementById('rebate-student-id').value.trim().toUpperCase();
  const from = document.getElementById('rebate-from-date').value;
  const to = document.getElementById('rebate-to-date').value;
  const reason = document.getElementById('rebate-reason').value.trim();

  if (to < from) {
    alert('End date cannot be prior to start date!');
    return;
  }

  const student = STATE.boarders.find(b => b.studentId === sid);
  if (!student) {
    alert(`Student ID [${sid}] not found.`);
    return;
  }

  const newRebate = {
    rebateId: STATE.rebates.length + 1,
    studentId: sid,
    studentName: student.name,
    fromDate: from,
    toDate: to,
    reason: reason,
    status: 'PENDING',
    remarks: 'Awaiting Warden Verification',
    appliedAt: new Date().toISOString().replace('T', ' ').substring(0, 19)
  };

  STATE.rebates.unshift(newRebate);
  logAudit('REBATE_APPLIED', 'REBATE_REQUESTS', String(newRebate.rebateId), null, `Dates: ${from} to ${to}`, sid);
  saveStateToStorage();
  renderRebatesView();
  document.getElementById('rebate-form').reset();
  alert(`Rebate leave request #${newRebate.rebateId} filed successfully!`);
}

// ----------------------------------------------------------------------------
// MODULE 4: BILLING ENGINE (EXPLICIT PL/SQL CURSOR EMULATION)
// ----------------------------------------------------------------------------
function renderBillingView() {
  const selectEl = document.getElementById('billing-student-select');
  selectEl.innerHTML = '';
  STATE.boarders.forEach(b => {
    const opt = document.createElement('option');
    opt.value = b.studentId;
    opt.textContent = `${b.studentId} — ${b.name}`;
    selectEl.appendChild(opt);
  });

  renderBillsHistoryTable();
}

function runCursorBillingCalculation() {
  const sid = document.getElementById('billing-student-select').value;
  const month = parseInt(document.getElementById('billing-month').value);
  const year = parseInt(document.getElementById('billing-year').value);

  const student = STATE.boarders.find(b => b.studentId === sid);
  if (!student) return;

  // Emulate Explicit Cursor c_swipes
  const relevantSwipes = STATE.swipes.filter(s => {
    if (s.studentId !== sid || s.status !== 'ACCEPTED') return false;
    const d = new Date(s.swipeDate);
    return (d.getMonth() + 1) === month && d.getFullYear() === year;
  });

  const totalSwipes = relevantSwipes.length;
  const grossAmount = relevantSwipes.reduce((sum, s) => sum + s.rateCharged, 0);

  // Emulate Explicit Cursor c_rebates
  const relevantRebates = STATE.rebates.filter(r => {
    if (r.studentId !== sid || r.status !== 'APPROVED') return false;
    const fromD = new Date(r.fromDate);
    const toD = new Date(r.toDate);
    return ((fromD.getMonth() + 1) === month && fromD.getFullYear() === year) || ((toD.getMonth() + 1) === month && toD.getFullYear() === year);
  });

  let rebateDays = 0;
  relevantRebates.forEach(r => {
    const startM = new Date(year, month - 1, 1);
    const endM = new Date(year, month, 0);
    const fromD = new Date(r.fromDate);
    const toD = new Date(r.toDate);
    const effFrom = fromD > startM ? fromD : startM;
    const effTo = toD < endM ? toD : endM;
    if (effTo >= effFrom) {
      rebateDays += Math.round((effTo - effFrom) / 86400000) + 1;
    }
  });

  const rebateCredit = rebateDays * 180.00; // ₹180 fixed daily rebate allowance
  const netPayable = Math.max(0, grossAmount - rebateCredit);

  // Atomic MERGE into Bills
  const existingIdx = STATE.bills.findIndex(b => b.studentId === sid && b.month === month && b.year === year);
  const billRecord = {
    billId: existingIdx >= 0 ? STATE.bills[existingIdx].billId : (STATE.bills.length + 1),
    studentId: sid,
    studentName: student.name,
    month: month,
    year: year,
    totalSwipes: totalSwipes,
    grossAmount: grossAmount,
    rebateDays: rebateDays,
    rebateCredit: rebateCredit,
    netPayable: netPayable,
    paymentStatus: 'PENDING',
    generatedAt: new Date().toISOString().replace('T', ' ').substring(0, 19)
  };

  if (existingIdx >= 0) {
    STATE.bills[existingIdx] = billRecord;
  } else {
    STATE.bills.unshift(billRecord);
  }

  logAudit('BILLING_CALCULATED', 'MONTHLY_BILLS', sid, null, `Gross=₹${grossAmount}, RebateDays=${rebateDays}, Net=₹${netPayable}`, 'BILLING_ENGINE');
  saveStateToStorage();

  // Display Cursor Progress & Results
  const resultCard = document.getElementById('billing-result-card');
  resultCard.style.display = 'block';
  document.getElementById('bill-res-swipes').textContent = totalSwipes;
  document.getElementById('bill-res-gross').textContent = `₹${grossAmount.toFixed(2)}`;
  document.getElementById('bill-res-reb-days').textContent = `${rebateDays} days`;
  document.getElementById('bill-res-reb-credit').textContent = `₹${rebateCredit.toFixed(2)}`;
  document.getElementById('bill-res-net').textContent = `₹${netPayable.toFixed(2)}`;

  renderBillsHistoryTable();
}

function renderBillsHistoryTable() {
  const tbody = document.getElementById('billing-history-body');
  tbody.innerHTML = '';
  STATE.bills.forEach(b => {
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td class="td-mono">#INV-${b.billId}</td>
      <td><strong>${b.studentName}</strong><br><span class="td-mono" style="font-size:11px;color:var(--color-fog)">${b.studentId}</span></td>
      <td class="td-mono">${b.month}/${b.year}</td>
      <td class="td-mono">${b.totalSwipes}</td>
      <td class="td-mono">₹${b.grossAmount.toFixed(2)}</td>
      <td class="td-mono">-₹${b.rebateCredit.toFixed(2)} (${b.rebateDays}d)</td>
      <td class="td-mono" style="color:var(--color-acid-lime);font-weight:600">₹${b.netPayable.toFixed(2)}</td>
      <td><span class="badge ${b.paymentStatus === 'PAID' ? 'badge-available' : 'badge-pending'}">${b.paymentStatus}</span></td>
    `;
    tbody.appendChild(tr);
  });
}

// ----------------------------------------------------------------------------
// MODULE 5: AUDIT LEDGER & ACTIVITY STREAM
// ----------------------------------------------------------------------------
function renderAuditView() {
  const tbody = document.getElementById('audit-table-body');
  tbody.innerHTML = '';
  STATE.auditLogs.forEach(a => {
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td class="td-mono">#${a.logId}</td>
      <td><span class="badge ${a.actionType.includes('DENIED') || a.actionType.includes('BLOCKED') ? 'badge-rejected' : 'badge-available'}">${a.actionType}</span></td>
      <td>${a.entityName}</td>
      <td class="td-mono">${a.entityId}</td>
      <td style="font-size:11px;color:var(--color-mist);max-width:320px;overflow:hidden;text-overflow:ellipsis">${a.newValue || a.oldValue || '-'}</td>
      <td class="td-mono" style="font-size:11px">${a.performedBy}</td>
      <td class="td-mono" style="font-size:11px;color:var(--color-fog)">${a.timestamp}</td>
    `;
    tbody.appendChild(tr);
  });
}

function logAudit(action, entity, eid, oldVal, newVal, performedBy) {
  const item = {
    logId: 500 + STATE.auditLogs.length + 1,
    actionType: action,
    entityName: entity,
    entityId: eid,
    oldValue: oldVal,
    newValue: newVal,
    performedBy: performedBy || 'SYSTEM',
    timestamp: new Date().toISOString().replace('T', ' ').substring(0, 19)
  };
  STATE.auditLogs.unshift(item);
  saveStateToStorage();
}

// ----------------------------------------------------------------------------
// MODULE 6: STUDENT PORTAL (AUTHENTICATED BOARDER VIEW)
// ----------------------------------------------------------------------------
function renderStudentPortalView() {
  const sid = STATE.currentUser?.studentId || '25BCE1642';
  const b = STATE.boarders.find(x => x.studentId === sid);
  if (!b) return;

  document.getElementById('sp-name').textContent = b.name;
  document.getElementById('sp-id').textContent = b.studentId;
  document.getElementById('sp-block-room').textContent = `${b.blockId} • Room ${b.roomNumber}`;
  document.getElementById('sp-mess-plan').textContent = b.messType;
  document.getElementById('sp-balance').textContent = `₹${b.walletBalance.toLocaleString('en-IN', { minimumFractionDigits: 2 })}`;

  // Today's meal slot availability
  const today = new Date().toISOString().split('T')[0];
  const slotsContainer = document.getElementById('sp-today-slots');
  slotsContainer.innerHTML = '';

  STATE.categories.forEach(cat => {
    const swiped = STATE.swipes.some(s => s.studentId === sid && s.categoryId === cat.categoryId && s.swipeDate === today && s.status === 'ACCEPTED');
    const div = document.createElement('div');
    div.className = `slot-card ${swiped ? 'swiped' : 'available'}`;
    div.innerHTML = `
      <div class="slot-header">
        <span class="slot-name">${cat.categoryName}</span>
        <span class="badge ${swiped ? 'badge-swiped' : 'badge-available'}">${swiped ? 'CONSUMED' : 'AVAILABLE'}</span>
      </div>
      <div class="slot-timing">${cat.startTime} – ${cat.endTime}</div>
    `;
    slotsContainer.appendChild(div);
  });

  // Student's personal swipe history
  const historyTbody = document.getElementById('sp-history-body');
  historyTbody.innerHTML = '';
  const mySwipes = STATE.swipes.filter(s => s.studentId === sid);
  mySwipes.slice(0, 10).forEach(s => {
    const cat = STATE.categories.find(c => c.categoryId === s.categoryId);
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td class="td-mono">${s.swipeDate}</td>
      <td class="td-mono">${s.swipeTime}</td>
      <td>${cat ? cat.categoryName : s.categoryId}</td>
      <td class="td-mono">₹${s.rateCharged.toFixed(2)}</td>
      <td><span class="badge badge-available">ACCEPTED</span></td>
    `;
    historyTbody.appendChild(tr);
  });

  // Pre-fill rebate form
  document.getElementById('sp-rebate-student-id').value = sid;

  // Update self-recharge balance display
  const rechargeDisp = document.getElementById('sp-recharge-balance-disp');
  if (rechargeDisp) {
    rechargeDisp.textContent = `₹${b.walletBalance.toLocaleString('en-IN', { minimumFractionDigits: 2 })}`;
  }
}

function setStudentRechargeAmount(amount) {
  document.getElementById('sp-recharge-amount').value = amount;
}

async function handleStudentSelfRecharge(e) {
  e.preventDefault();
  const sid = STATE.currentUser?.studentId || '25BCE1642';
  const amount = parseFloat(document.getElementById('sp-recharge-amount').value);
  if (!amount || amount <= 0) {
    alert('Please enter a valid deposit amount.');
    return;
  }

  if (STATE.isBackendConnected) {
    try {
      const res = await fetch(`${STATE.apiBase}/students/add-funds`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ studentId: sid, amount: String(amount), source: 'STUDENT' })
      });
      if (res.ok) {
        const data = await res.json();
        const b = STATE.boarders.find(x => x.studentId === sid);
        if (b) b.walletBalance = data.newBalance;
      }
    } catch (err) {
      console.warn('Backend student recharge failed, applying local state:', err);
    }
  }

  const b = STATE.boarders.find(x => x.studentId === sid);
  if (b) {
    if (!STATE.isBackendConnected) {
      const prevBal = b.walletBalance;
      b.walletBalance += amount;
      logAudit('WALLET_TOP_UP', 'STUDENTS', sid, `PREV=₹${prevBal.toFixed(2)}`, `CREDIT=₹${amount.toFixed(2)}; NEW=₹${b.walletBalance.toFixed(2)}; SOURCE=STUDENT`, sid);
    }
  }

  saveStateToStorage();
  document.getElementById('sp-recharge-amount').value = '';
  renderStudentPortalView();
  alert(`Wallet recharge of ₹${amount.toFixed(2)} successful! New Balance: ₹${b ? b.walletBalance.toFixed(2) : ''}`);
}

function handleStudentSelfRebateSubmit(e) {
  e.preventDefault();
  const sid = STATE.currentUser?.studentId || '25BCE1642';
  const from = document.getElementById('sp-rebate-from').value;
  const to = document.getElementById('sp-rebate-to').value;
  const reason = document.getElementById('sp-rebate-reason').value.trim();

  if (to < from) {
    alert('End date cannot precede start date.');
    return;
  }

  const b = STATE.boarders.find(x => x.studentId === sid);
  const newRebate = {
    rebateId: STATE.rebates.length + 1,
    studentId: sid,
    studentName: b ? b.name : sid,
    fromDate: from,
    toDate: to,
    reason: reason,
    status: 'PENDING',
    remarks: 'Submitted by student via Portal',
    appliedAt: new Date().toISOString().replace('T', ' ').substring(0, 19)
  };

  STATE.rebates.unshift(newRebate);
  logAudit('REBATE_APPLIED', 'REBATE_REQUESTS', String(newRebate.rebateId), null, `Filed by student: ${from} to ${to}`, sid);
  saveStateToStorage();
  alert(`Rebate leave application #${newRebate.rebateId} submitted. Status: PENDING warden review.`);
  document.getElementById('sp-rebate-form').reset();
}

// ----------------------------------------------------------------------------
// ABOUT & ARCHITECTURE MODAL
// ----------------------------------------------------------------------------
function openAboutModal() {
  document.getElementById('about-modal').classList.add('open');
}

function closeAboutModal() {
  document.getElementById('about-modal').classList.remove('open');
}

// ----------------------------------------------------------------------------
// EVENT LISTENERS & LIFECYCLE INITIALIZATION
// ----------------------------------------------------------------------------
document.addEventListener('DOMContentLoaded', async () => {
  loadStateFromStorage();

  // Navigation listener
  document.querySelectorAll('.nav-item').forEach(btn => {
    btn.addEventListener('click', () => {
      const view = btn.dataset.view;
      if (view) navigateTo(view);
    });
  });

  // Quick 1-click test login buttons
  document.getElementById('quick-login-warden')?.addEventListener('click', () => {
    document.getElementById('auth-username').value = 'admin';
    document.getElementById('auth-password').value = 'admin123';
    performLogin('admin', 'admin123');
  });

  document.getElementById('quick-login-student')?.addEventListener('click', () => {
    document.getElementById('auth-username').value = '25BCE1642';
    document.getElementById('auth-password').value = 'student123';
    performLogin('25BCE1642', 'student123');
  });

  // Check backend server & start
  await checkBackendConnection();
  initAuthGateway();
});
