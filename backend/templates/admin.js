/**
 * Palestine Martyrs Admin Panel JavaScript
 * Handles authentication, data loading, and admin operations
 */

// API Configuration
const API_BASE_URL = window.location.origin; // Use same origin as the admin panel
let authToken = localStorage.getItem('adminToken');
let currentUser = null;

// Initialize the application
document.addEventListener('DOMContentLoaded', function() {
    if (authToken) {
        verifyToken();
    } else {
        showLoginPage();
    }
    
    setupEventListeners();
});

// Setup event listeners
function setupEventListeners() {
    // Login form
    document.getElementById('loginForm').addEventListener('submit', handleLogin);
    
    // Tab switching
    document.getElementById('mainTabs').addEventListener('click', handleTabSwitch);
}

// Authentication Functions
async function handleLogin(e) {
    e.preventDefault();
    
    const username = document.getElementById('username').value;
    const password = document.getElementById('password').value;
    
    try {
        const response = await fetch(`${API_BASE_URL}/auth/login`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ username, password }),
        });
        
        if (!response.ok) {
            throw new Error('خطأ في اسم المستخدم أو كلمة المرور');
        }
        
        const data = await response.json();
        authToken = data.access_token;
        currentUser = data.user;
        
        localStorage.setItem('adminToken', authToken);
        
        showMainDashboard();
        loadInitialData();
        
    } catch (error) {
        showError('loginError', error.message);
    }
}

async function verifyToken() {
    try {
        const response = await fetch(`${API_BASE_URL}/auth/me`, {
            headers: {
                'Authorization': `Bearer ${authToken}`,
            },
        });
        
        if (!response.ok) {
            throw new Error('Invalid token');
        }
        
        currentUser = await response.json();
        
        if (currentUser.user_type !== 'admin') {
            throw new Error('غير مخول بالوصول لهذه الصفحة');
        }
        
        showMainDashboard();
        loadInitialData();
        
    } catch (error) {
        logout();
    }
}

function logout() {
    authToken = null;
    currentUser = null;
    localStorage.removeItem('adminToken');
    showLoginPage();
}

// UI Functions
function showLoginPage() {
    document.getElementById('loginPage').style.display = 'flex';
    document.getElementById('mainDashboard').style.display = 'none';
}

function showMainDashboard() {
    document.getElementById('loginPage').style.display = 'none';
    document.getElementById('mainDashboard').style.display = 'block';
    document.getElementById('currentUser').textContent = currentUser.full_name;
}

function showError(elementId, message) {
    const errorElement = document.getElementById(elementId);
    errorElement.textContent = message;
    errorElement.style.display = 'block';
    setTimeout(() => {
        errorElement.style.display = 'none';
    }, 5000);
}

// Data Loading Functions
async function loadInitialData() {
    await loadStatistics();
    await loadMartyrs();
}

async function loadStatistics() {
    try {
        const response = await fetch(`${API_BASE_URL}/admin/stats`, {
            headers: {
                'Authorization': `Bearer ${authToken}`,
            },
        });
        
        if (!response.ok) {
            throw new Error('فشل في تحميل الإحصائيات');
        }
        
        const stats = await response.json();
        
        document.getElementById('totalMartyrs').textContent = stats.total_martyrs;
        document.getElementById('totalInjured').textContent = stats.total_injured;
        document.getElementById('totalPrisoners').textContent = stats.total_prisoners;
        document.getElementById('totalPending').textContent = 
            stats.pending_martyrs + stats.pending_injured + stats.pending_prisoners;
            
    } catch (error) {
        console.error('Error loading statistics:', error);
    }
}

async function loadMartyrs() {
    showLoading('martyrsLoading');
    
    try {
        const response = await fetch(`${API_BASE_URL}/martyrs`, {
            headers: {
                'Authorization': `Bearer ${authToken}`,
            },
        });
        
        if (!response.ok) {
            throw new Error('فشل في تحميل بيانات الشهداء');
        }
        
        const martyrs = await response.json();
        renderMartyrsTable(martyrs);
        
    } catch (error) {
        document.getElementById('martyrsTable').innerHTML = 
            `<div class="alert alert-danger">${error.message}</div>`;
    } finally {
        hideLoading('martyrsLoading');
    }
}

async function loadInjured() {
    showLoading('injuredLoading');
    
    try {
        const response = await fetch(`${API_BASE_URL}/injured`, {
            headers: {
                'Authorization': `Bearer ${authToken}`,
            },
        });
        
        if (!response.ok) {
            throw new Error('فشل في تحميل بيانات الجرحى');
        }
        
        const injured = await response.json();
        renderInjuredTable(injured);
        
    } catch (error) {
        document.getElementById('injuredTable').innerHTML = 
            `<div class="alert alert-danger">${error.message}</div>`;
    } finally {
        hideLoading('injuredLoading');
    }
}

async function loadPrisoners() {
    showLoading('prisonersLoading');
    
    try {
        const response = await fetch(`${API_BASE_URL}/prisoners`, {
            headers: {
                'Authorization': `Bearer ${authToken}`,
            },
        });
        
        if (!response.ok) {
            throw new Error('فشل في تحميل بيانات الأسرى');
        }
        
        const prisoners = await response.json();
        renderPrisonersTable(prisoners);
        
    } catch (error) {
        document.getElementById('prisonersTable').innerHTML = 
            `<div class="alert alert-danger">${error.message}</div>`;
    } finally {
        hideLoading('prisonersLoading');
    }
}

async function loadUsers() {
    showLoading('usersLoading');
    
    try {
        const response = await fetch(`${API_BASE_URL}/admin/users`, {
            headers: {
                'Authorization': `Bearer ${authToken}`,
            },
        });
        
        if (!response.ok) {
            throw new Error('فشل في تحميل بيانات المستخدمين');
        }
        
        const users = await response.json();
        renderUsersTable(users);
        
    } catch (error) {
        document.getElementById('usersTable').innerHTML = 
            `<div class="alert alert-danger">${error.message}</div>`;
    } finally {
        hideLoading('usersLoading');
    }
}

// Render Functions
function renderMartyrsTable(martyrs) {
    if (martyrs.length === 0) {
        document.getElementById('martyrsTable').innerHTML = 
            '<div class="text-center text-muted py-4">لا توجد بيانات للعرض</div>';
        return;
    }
    
    const table = `
        <div class="table-responsive">
            <table class="table table-hover">
                <thead class="table-dark">
                    <tr>
                        <th>الرقم</th>
                        <th>الاسم الكامل</th>
                        <th>القبيلة</th>
                        <th>تاريخ الاستشهاد</th>
                        <th>مكان الاستشهاد</th>
                        <th>الحالة</th>
                        <th>الإجراءات</th>
                    </tr>
                </thead>
                <tbody>
                    ${martyrs.map(martyr => `
                        <tr>
                            <td>${martyr.id}</td>
                            <td>${martyr.full_name}</td>
                            <td>${martyr.tribe}</td>
                            <td>${formatDate(martyr.death_date)}</td>
                            <td>${martyr.death_place}</td>
                            <td>
                                <span class="badge status-${martyr.status}">
                                    ${getStatusText(martyr.status)}
                                </span>
                            </td>
                            <td>
                                ${renderActionButtons('martyrs', martyr.id, martyr.status)}
                            </td>
                        </tr>
                    `).join('')}
                </tbody>
            </table>
        </div>
    `;
    
    document.getElementById('martyrsTable').innerHTML = table;
}

function renderInjuredTable(injured) {
    if (injured.length === 0) {
        document.getElementById('injuredTable').innerHTML = 
            '<div class="text-center text-muted py-4">لا توجد بيانات للعرض</div>';
        return;
    }
    
    const table = `
        <div class="table-responsive">
            <table class="table table-hover">
                <thead class="table-dark">
                    <tr>
                        <th>الرقم</th>
                        <th>الاسم الكامل</th>
                        <th>القبيلة</th>
                        <th>تاريخ الإصابة</th>
                        <th>مكان الإصابة</th>
                        <th>نوع الإصابة</th>
                        <th>الحالة</th>
                        <th>الإجراءات</th>
                    </tr>
                </thead>
                <tbody>
                    ${injured.map(person => `
                        <tr>
                            <td>${person.id}</td>
                            <td>${person.full_name}</td>
                            <td>${person.tribe}</td>
                            <td>${formatDate(person.injury_date)}</td>
                            <td>${person.injury_place}</td>
                            <td>${person.injury_type}</td>
                            <td>
                                <span class="badge status-${person.status}">
                                    ${getStatusText(person.status)}
                                </span>
                            </td>
                            <td>
                                ${renderActionButtons('injured', person.id, person.status)}
                            </td>
                        </tr>
                    `).join('')}
                </tbody>
            </table>
        </div>
    `;
    
    document.getElementById('injuredTable').innerHTML = table;
}

function renderPrisonersTable(prisoners) {
    if (prisoners.length === 0) {
        document.getElementById('prisonersTable').innerHTML = 
            '<div class="text-center text-muted py-4">لا توجد بيانات للعرض</div>';
        return;
    }
    
    const table = `
        <div class="table-responsive">
            <table class="table table-hover">
                <thead class="table-dark">
                    <tr>
                        <th>الرقم</th>
                        <th>الاسم الكامل</th>
                        <th>القبيلة</th>
                        <th>تاريخ الاعتقال</th>
                        <th>مكان الاعتقال</th>
                        <th>مكان الاحتجاز</th>
                        <th>الحالة</th>
                        <th>الإجراءات</th>
                    </tr>
                </thead>
                <tbody>
                    ${prisoners.map(prisoner => `
                        <tr>
                            <td>${prisoner.id}</td>
                            <td>${prisoner.full_name}</td>
                            <td>${prisoner.tribe}</td>
                            <td>${formatDate(prisoner.capture_date)}</td>
                            <td>${prisoner.capture_place}</td>
                            <td>${prisoner.detention_place || 'غير محدد'}</td>
                            <td>
                                <span class="badge status-${prisoner.status}">
                                    ${getStatusText(prisoner.status)}
                                </span>
                            </td>
                            <td>
                                ${renderActionButtons('prisoners', prisoner.id, prisoner.status)}
                            </td>
                        </tr>
                    `).join('')}
                </tbody>
            </table>
        </div>
    `;
    
    document.getElementById('prisonersTable').innerHTML = table;
}

function renderUsersTable(users) {
    if (users.length === 0) {
        document.getElementById('usersTable').innerHTML = 
            '<div class="text-center text-muted py-4">لا توجد بيانات للعرض</div>';
        return;
    }
    
    const table = `
        <div class="table-responsive">
            <table class="table table-hover">
                <thead class="table-dark">
                    <tr>
                        <th>الرقم</th>
                        <th>اسم المستخدم</th>
                        <th>الاسم الكامل</th>
                        <th>نوع المستخدم</th>
                        <th>رقم الهاتف</th>
                        <th>تاريخ التسجيل</th>
                        <th>آخر دخول</th>
                    </tr>
                </thead>
                <tbody>
                    ${users.map(user => `
                        <tr>
                            <td>${user.id}</td>
                            <td>${user.username}</td>
                            <td>${user.full_name}</td>
                            <td>
                                <span class="badge ${user.user_type === 'admin' ? 'bg-danger' : 'bg-secondary'}">
                                    ${user.user_type === 'admin' ? 'مسؤول' : 'مستخدم عادي'}
                                </span>
                            </td>
                            <td>${user.phone_number || 'غير محدد'}</td>
                            <td>${formatDate(user.created_at)}</td>
                            <td>${user.last_login ? formatDate(user.last_login) : 'لم يسجل دخول'}</td>
                        </tr>
                    `).join('')}
                </tbody>
            </table>
        </div>
    `;
    
    document.getElementById('usersTable').innerHTML = table;
}

// Helper Functions
function renderActionButtons(type, id, status) {
    if (status === 'pending') {
        return `
            <button class="btn btn-success btn-sm btn-action" onclick="updateStatus('${type}', ${id}, 'approved')">
                <i class="bi bi-check-lg"></i> موافقة
            </button>
            <button class="btn btn-danger btn-sm btn-action" onclick="updateStatus('${type}', ${id}, 'rejected')">
                <i class="bi bi-x-lg"></i> رفض
            </button>
        `;
    }
    
    return `
        <button class="btn btn-secondary btn-sm btn-action" disabled>
            <i class="bi bi-check-lg"></i> تمت المراجعة
        </button>
    `;
}

async function updateStatus(type, id, status) {
    const notes = status === 'rejected' ? 
        prompt('أدخل سبب الرفض:') : 
        prompt('ملاحظات إضافية (اختياري):');
    
    if (status === 'rejected' && !notes) {
        alert('يجب إدخال سبب الرفض');
        return;
    }
    
    try {
        const response = await fetch(`${API_BASE_URL}/${type}/${id}/status`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${authToken}`,
            },
            body: JSON.stringify({
                status: status,
                admin_notes: notes || null,
            }),
        });
        
        if (!response.ok) {
            throw new Error('فشل في تحديث الحالة');
        }
        
        // Reload the current tab data
        const activeTab = document.querySelector('.nav-link.active').getAttribute('href').substring(1);
        await loadTabData(activeTab);
        await loadStatistics();
        
        alert('تم تحديث الحالة بنجاح');
        
    } catch (error) {
        alert(`خطأ: ${error.message}`);
    }
}

function getStatusText(status) {
    const statusMap = {
        'pending': 'في انتظار المراجعة',
        'approved': 'تم التوثيق',
        'rejected': 'مرفوض'
    };
    return statusMap[status] || status;
}

function formatDate(dateString) {
    if (!dateString) return 'غير محدد';
    
    const date = new Date(dateString);
    return date.toLocaleDateString('ar-SA', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    });
}

function showLoading(elementId) {
    document.getElementById(elementId).style.display = 'block';
}

function hideLoading(elementId) {
    document.getElementById(elementId).style.display = 'none';
}

function handleTabSwitch(e) {
    if (e.target.dataset.bsToggle === 'pill') {
        const tabName = e.target.getAttribute('href').substring(1);
        setTimeout(() => loadTabData(tabName), 100);
    }
}

async function loadTabData(tabName) {
    switch (tabName) {
        case 'martyrs':
            await loadMartyrs();
            break;
        case 'injured':
            await loadInjured();
            break;
        case 'prisoners':
            await loadPrisoners();
            break;
        case 'users':
            await loadUsers();
            break;
    }
}