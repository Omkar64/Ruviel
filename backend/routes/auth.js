import express from 'express';
import bcrypt from 'bcrypt';
import supabase from '../utils/auth.js';
import { generateToken } from '../utils/jwt.js';
import { requireAuth } from '../middleware/auth.js';

const router = express.Router();

// =============================
// SIGNUP
// =============================
router.post('/signup', async (req, res) => {
  try {
    const { email, password } = req.body;

    const hash = await bcrypt.hash(password, 10);

    const { data, error } = await supabase
      .from('users')
      .insert({
        email,
        password_hash: hash,
      })
      .select()
      .single();

    if (error) throw error;

    const token = generateToken(data);

    res.json({ token });
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

// =============================
// LOGIN
// =============================
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    const { data: user } = await supabase
      .from('users')
      .select('*')
      .eq('email', email)
      .single();

    if (!user) return res.status(401).json({ error: 'Invalid credentials' });

    const match = await bcrypt.compare(password, user.password_hash);

    if (!match) return res.status(401).json({ error: 'Invalid credentials' });

    const token = generateToken(user);

    res.json({ token });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// =============================
// ME
// =============================
router.get('/me', requireAuth, async (req, res) => {
  const { data } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', req.userId)
    .single();

  res.json(data);
});

export default router;