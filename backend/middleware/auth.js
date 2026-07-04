import { verifyToken } from '../utils/jwt.js';

export function requireAuth(req, res, next) {
  try {
    const header = req.headers.authorization;

    if (!header || !header.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'No token provided' });
    }

    const token = header.split(' ')[1];
    const decoded = verifyToken(token);

    req.user = decoded;
    req.userId = decoded.id;

    next();
  } catch {
    return res.status(401).json({ error: 'Invalid token' });
  }
}

export function optionalJWT(req, res, next) {
  try {
    const header = req.headers.authorization;

    if (!header || !header.startsWith('Bearer ')) {
      return next();
    }

    const token = header.split(' ')[1];
    const decoded = verifyToken(token);

    req.user = decoded;
    req.userId = decoded.id;
    
    next();
  } catch {
    next();
  }
}