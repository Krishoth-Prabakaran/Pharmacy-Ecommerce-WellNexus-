// backend/utils/apiResponse.js
/**
 * Standardized API response formatter
 * Ensures all API responses follow the same format
 */

class ApiResponse {
  /**
   * Success response
   * @param {any} data - Response data
   * @param {string} message - Success message
   * @param {number} statusCode - HTTP status code (default: 200)
   */
  static success(data, message = 'Success', statusCode = 200) {
    return {
      statusCode,
      response: {
        success: true,
        message,
        data: data || null,
      },
    };
  }

  /**
   * Error response
   * @param {string} message - Error message
   * @param {number} statusCode - HTTP status code (default: 400)
   * @param {any} error - Error details (for development)
   */
  static error(message = 'Error', statusCode = 400, error = null) {
    return {
      statusCode,
      response: {
        success: false,
        message,
        ...(process.env.NODE_ENV === 'development' && error && { error: error.message }),
      },
    };
  }

  /**
   * Paginated response
   * @param {array} data - Data array
   * @param {number} total - Total count
   * @param {number} page - Current page
   * @param {number} limit - Items per page
   * @param {string} message - Success message
   */
  static paginated(data, total, page, limit, message = 'Success') {
    return {
      statusCode: 200,
      response: {
        success: true,
        message,
        data,
        pagination: {
          total,
          page,
          limit,
          pages: Math.ceil(total / limit),
        },
      },
    };
  }
}

module.exports = ApiResponse;
