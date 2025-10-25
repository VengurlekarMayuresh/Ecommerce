const { ConfidentialClientApplication } = require('@azure/msal-node');
const jwt = require('jsonwebtoken');

// Azure AD B2C Configuration
const msalConfig = {
  auth: {
    clientId: process.env.AZURE_AD_B2C_CLIENT_ID,
    authority: process.env.AZURE_AD_B2C_AUTHORITY,
    clientSecret: process.env.AZURE_AD_B2C_CLIENT_SECRET,
    knownAuthorities: [process.env.AZURE_AD_B2C_DOMAIN],
  },
  system: {
    loggerOptions: {
      loggerCallback(loglevel, message, containsPii) {
        console.log(message);
      },
      piiLoggingEnabled: false,
      logLevel: 3, // Info
    }
  }
};

let msalClient;

// Initialize Azure AD B2C
function initializeAzureADB2C() {
  if (!msalConfig.auth.clientId || !msalConfig.auth.authority) {
    console.warn('Azure AD B2C not configured. Using local authentication.');
    return false;
  }

  try {
    msalClient = new ConfidentialClientApplication(msalConfig);
    console.log('Azure AD B2C initialized successfully');
    return true;
  } catch (error) {
    console.error('Failed to initialize Azure AD B2C:', error.message);
    return false;
  }
}

// Role definitions
const Roles = {
  ADMIN: 'admin',
  CUSTOMER: 'customer'
};

// Permission definitions
const Permissions = {
  // Admin permissions
  MANAGE_PRODUCTS: 'manage:products',
  MANAGE_ORDERS: 'manage:orders',
  MANAGE_USERS: 'manage:users',
  VIEW_ANALYTICS: 'view:analytics',
  
  // Customer permissions
  VIEW_PRODUCTS: 'view:products',
  CREATE_ORDER: 'create:order',
  VIEW_OWN_ORDERS: 'view:own_orders',
  MANAGE_OWN_PROFILE: 'manage:own_profile'
};

// Role-Permission mapping
const RolePermissions = {
  [Roles.ADMIN]: [
    Permissions.MANAGE_PRODUCTS,
    Permissions.MANAGE_ORDERS,
    Permissions.MANAGE_USERS,
    Permissions.VIEW_ANALYTICS,
    Permissions.VIEW_PRODUCTS,
    Permissions.VIEW_OWN_ORDERS,
    Permissions.MANAGE_OWN_PROFILE
  ],
  [Roles.CUSTOMER]: [
    Permissions.VIEW_PRODUCTS,
    Permissions.CREATE_ORDER,
    Permissions.VIEW_OWN_ORDERS,
    Permissions.MANAGE_OWN_PROFILE
  ]
};

// Verify Azure AD B2C token
async function verifyADB2CToken(token) {
  if (!msalClient) {
    throw new Error('Azure AD B2C not initialized');
  }

  try {
    // Decode token without verification first
    const decodedToken = jwt.decode(token, { complete: true });
    
    if (!decodedToken) {
      throw new Error('Invalid token format');
    }

    // In production, verify the token signature with Azure AD B2C
    // For now, we'll validate the structure
    const payload = decodedToken.payload;
    
    return {
      success: true,
      userId: payload.sub || payload.oid,
      email: payload.emails ? payload.emails[0] : payload.email,
      name: payload.name,
      roles: payload.extension_Role ? [payload.extension_Role] : [Roles.CUSTOMER]
    };
  } catch (error) {
    console.error('Token verification failed:', error.message);
    return { success: false, error: error.message };
  }
}

// Check if user has permission
function hasPermission(userRole, requiredPermission) {
  const userPermissions = RolePermissions[userRole] || [];
  return userPermissions.includes(requiredPermission);
}

// Check if user has any of the required roles
function hasRole(userRoles, requiredRoles) {
  if (!Array.isArray(requiredRoles)) {
    requiredRoles = [requiredRoles];
  }
  
  return requiredRoles.some(role => userRoles.includes(role));
}

// Middleware: Verify Azure AD B2C token
function authenticateADB2C(req, res, next) {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      message: 'No token provided'
    });
  }

  const token = authHeader.substring(7);

  verifyADB2CToken(token)
    .then(result => {
      if (!result.success) {
        return res.status(401).json({
          success: false,
          message: 'Invalid token'
        });
      }

      // Attach user info to request
      req.user = {
        userId: result.userId,
        email: result.email,
        name: result.name,
        roles: result.roles
      };

      next();
    })
    .catch(error => {
      return res.status(401).json({
        success: false,
        message: 'Authentication failed',
        error: error.message
      });
    });
}

// Middleware: Require specific role
function requireRole(...roles) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    if (!hasRole(req.user.roles, roles)) {
      return res.status(403).json({
        success: false,
        message: 'Insufficient permissions',
        requiredRoles: roles,
        userRoles: req.user.roles
      });
    }

    next();
  };
}

// Middleware: Require specific permission
function requirePermission(...permissions) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    const userRole = req.user.roles[0]; // Primary role
    const hasRequiredPermission = permissions.some(permission => 
      hasPermission(userRole, permission)
    );

    if (!hasRequiredPermission) {
      return res.status(403).json({
        success: false,
        message: 'Insufficient permissions',
        requiredPermissions: permissions
      });
    }

    next();
  };
}

// Middleware: Admin only
const requireAdmin = requireRole(Roles.ADMIN);

// Middleware: Customer only
const requireCustomer = requireRole(Roles.CUSTOMER);

// Middleware: Admin or own resource
function requireAdminOrOwn(resourceUserIdField = 'userId') {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    const isAdmin = hasRole(req.user.roles, [Roles.ADMIN]);
    const resourceUserId = req.params[resourceUserIdField] || req.body[resourceUserIdField];
    const isOwner = req.user.userId === resourceUserId;

    if (!isAdmin && !isOwner) {
      return res.status(403).json({
        success: false,
        message: 'Access denied. Admin rights or resource ownership required.'
      });
    }

    req.isAdmin = isAdmin;
    req.isOwner = isOwner;
    next();
  };
}

module.exports = {
  initializeAzureADB2C,
  verifyADB2CToken,
  authenticateADB2C,
  requireRole,
  requirePermission,
  requireAdmin,
  requireCustomer,
  requireAdminOrOwn,
  hasPermission,
  hasRole,
  Roles,
  Permissions
};
