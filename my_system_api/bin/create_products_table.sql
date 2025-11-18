-- جدول المنتجات
CREATE TABLE IF NOT EXISTS products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  cost_price REAL,
  sell_price REAL,
  category TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

-- إضافة بعض المنتجات التجريبية
INSERT INTO products (name, cost_price, sell_price, category, created_at, updated_at) 
VALUES 
  ('PUBG Mobile', 4500, 5000, 'ألعاب', datetime('now'), datetime('now')),
  ('Free Fire', 2700, 3000, 'ألعاب', datetime('now'), datetime('now')),
  ('Netflix', 13500, 15000, 'اشتراكات', datetime('now'), datetime('now')),
  ('Spotify', 7200, 8000, 'اشتراكات', datetime('now'), datetime('now')),
  ('PSN Card', 22500, 25000, 'ألعاب', datetime('now'), datetime('now')),
  ('iTunes', 9000, 10000, 'اشتراكات', datetime('now'), datetime('now'));
