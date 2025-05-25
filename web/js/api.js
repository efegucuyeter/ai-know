// API Base URL
const API_BASE_URL = 'http://localhost:8000/api';

// Token yönetimi
class TokenManager {
    static setToken(token) {
        localStorage.setItem('access_token', token);
    }
    
    static getToken() {
        return localStorage.getItem('access_token');
    }
    
    static removeToken() {
        localStorage.removeItem('access_token');
    }
    
    static isLoggedIn() {
        return !!this.getToken();
    }
}

// API çağrıları için yardımcı fonksiyon
async function apiCall(endpoint, options = {}) {
    const url = `${API_BASE_URL}${endpoint}`;
    const token = TokenManager.getToken();
    
    const defaultOptions = {
        headers: {
            'Content-Type': 'application/json',
        }
    };
    
    if (token) {
        defaultOptions.headers['Authorization'] = `Bearer ${token}`;
    }
    
    const finalOptions = {
        ...defaultOptions,
        ...options,
        headers: {
            ...defaultOptions.headers,
            ...options.headers
        }
    };
    
    try {
        const response = await fetch(url, finalOptions);
        
        if (!response.ok) {
            if (response.status === 401) {
                TokenManager.removeToken();
                window.location.href = 'login.html';
                return;
            }
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        return await response.json();
    } catch (error) {
        console.error('API call failed:', error);
        throw error;
    }
}

// Auth API
class AuthAPI {
    static async register(email, username, password) {
        return await apiCall('/auth/register', {
            method: 'POST',
            body: JSON.stringify({
                email,
                username,
                password
            })
        });
    }
    
    static async login(email, password) {
        const response = await apiCall('/auth/login', {
            method: 'POST',
            body: JSON.stringify({
                email,
                password
            })
        });
        
        if (response.access_token) {
            TokenManager.setToken(response.access_token);
        }
        
        return response;
    }
    
    static async getCurrentUser() {
        return await apiCall('/auth/me');
    }
    
    static async updateProfile(updateData) {
        return await apiCall('/auth/me', {
            method: 'PUT',
            body: JSON.stringify(updateData)
        });
    }
    
    static logout() {
        TokenManager.removeToken();
        window.location.href = 'login.html';
    }
}

// Categories API
class CategoriesAPI {
    static async getCategories() {
        return await apiCall('/categories');
    }
    
    static async createCategory(name, description, imageUrl) {
        return await apiCall('/categories', {
            method: 'POST',
            body: JSON.stringify({
                name,
                description,
                image_url: imageUrl
            })
        });
    }
}

// Quizzes API
class QuizzesAPI {
    static async getQuizzes(categoryId = null, skip = 0, limit = 100) {
        let endpoint = `/quizzes?skip=${skip}&limit=${limit}`;
        if (categoryId) {
            endpoint += `&category_id=${categoryId}`;
        }
        return await apiCall(endpoint);
    }
    
    static async getQuiz(quizId) {
        return await apiCall(`/quizzes/${quizId}`);
    }
    
    static async createQuiz(quizData) {
        return await apiCall('/quizzes', {
            method: 'POST',
            body: JSON.stringify(quizData)
        });
    }
    
    static async submitQuizAttempt(quizId, answers, timeTaken) {
        return await apiCall(`/quizzes/${quizId}/attempt`, {
            method: 'POST',
            body: JSON.stringify({
                quiz_id: quizId,
                answers,
                time_taken: timeTaken
            })
        });
    }
}

// User API
class UserAPI {
    static async getUserAttempts(skip = 0, limit = 100) {
        return await apiCall(`/user/attempts?skip=${skip}&limit=${limit}`);
    }
}

// Leaderboard API
class LeaderboardAPI {
    static async getLeaderboard(page = 1, limit = 10) {
        return await apiCall(`/leaderboard?page=${page}&limit=${limit}`);
    }
}

// Statistics API
class StatisticsAPI {
    static async getStatistics() {
        return await apiCall('/statistics');
    }
}

// AI API
class AIAPI {
    static async generateQuestions(category, difficulty, questionCount, topic = null) {
        return await apiCall('/ai/generate-questions', {
            method: 'POST',
            body: JSON.stringify({
                category,
                difficulty,
                question_count: questionCount,
                topic
            })
        });
    }
}

// Admin API
class AdminAPI {
    static async getAllUsers(page = 1, limit = 10) {
        return await apiCall(`/admin/users?page=${page}&limit=${limit}`);
    }
    
    static async updateUser(userId, updateData) {
        return await apiCall(`/admin/users/${userId}`, {
            method: 'PUT',
            body: JSON.stringify(updateData)
        });
    }
    
    static async deleteUser(userId) {
        return await apiCall(`/admin/users/${userId}`, {
            method: 'DELETE'
        });
    }
    
    static async getAllQuizzes(page = 1, limit = 10) {
        return await apiCall(`/admin/quizzes?page=${page}&limit=${limit}`);
    }
    
    static async updateQuiz(quizId, updateData) {
        return await apiCall(`/admin/quizzes/${quizId}`, {
            method: 'PUT',
            body: JSON.stringify(updateData)
        });
    }
    
    static async deleteQuiz(quizId) {
        return await apiCall(`/admin/quizzes/${quizId}`, {
            method: 'DELETE'
        });
    }
    
    static async getAdminStatistics() {
        return await apiCall('/admin/statistics');
    }
}

// Sayfa yüklendiğinde login kontrolü
document.addEventListener('DOMContentLoaded', function() {
    const currentPage = window.location.pathname.split('/').pop();
    const publicPages = ['login.html', 'index.html', ''];
    
    if (!publicPages.includes(currentPage) && !TokenManager.isLoggedIn()) {
        window.location.href = 'login.html';
    }
});

// Utility fonksiyonlar
function showAlert(message, type = 'info') {
    // Bootstrap alert göster
    const alertDiv = document.createElement('div');
    alertDiv.className = `alert alert-${type} alert-dismissible fade show`;
    alertDiv.innerHTML = `
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;
    
    const container = document.querySelector('.container') || document.body;
    container.insertBefore(alertDiv, container.firstChild);
    
    // 5 saniye sonra otomatik kapat
    setTimeout(() => {
        alertDiv.remove();
    }, 5000);
}

function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleDateString('tr-TR');
}

function formatTime(seconds) {
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
} 