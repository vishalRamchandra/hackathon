-- ============================================================
-- NATION BUILDER - SQL Server Database Schema
-- Run this file in Microsoft SQL Server
-- ============================================================

IF DB_ID('nation_builder') IS NULL
BEGIN
  CREATE DATABASE nation_builder;
END;
GO

USE nation_builder;
GO

IF OBJECT_ID('dbo.user_badges', 'U') IS NOT NULL DROP TABLE dbo.user_badges;
IF OBJECT_ID('dbo.daily_progress', 'U') IS NOT NULL DROP TABLE dbo.daily_progress;
IF OBJECT_ID('dbo.xp_log', 'U') IS NOT NULL DROP TABLE dbo.xp_log;
IF OBJECT_ID('dbo.sessions', 'U') IS NOT NULL DROP TABLE dbo.sessions;
IF OBJECT_ID('dbo.users', 'U') IS NOT NULL DROP TABLE dbo.users;
GO

CREATE TABLE dbo.users (
  uid NVARCHAR(40) PRIMARY KEY,
  name NVARCHAR(100) NOT NULL,
  email NVARCHAR(150) NOT NULL UNIQUE,
  phone NVARCHAR(15) NOT NULL,
  state NVARCHAR(60) NOT NULL,
  pass_hash NVARCHAR(255) NOT NULL,
  xp INT NOT NULL DEFAULT 50,
  streak INT NOT NULL DEFAULT 1,
  last_login DATE NULL,
  joined_at DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

CREATE TABLE dbo.user_badges (
  id INT IDENTITY(1,1) PRIMARY KEY,
  uid NVARCHAR(40) NOT NULL,
  badge_id NVARCHAR(50) NOT NULL,
  earned_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
  CONSTRAINT UQ_user_badges_uid_badge UNIQUE (uid, badge_id),
  CONSTRAINT FK_user_badges_users FOREIGN KEY (uid) REFERENCES dbo.users(uid) ON DELETE CASCADE
);
GO

CREATE TABLE dbo.daily_progress (
  id INT IDENTITY(1,1) PRIMARY KEY,
  uid NVARCHAR(40) NOT NULL,
  progress_date DATE NOT NULL,
  is_read BIT NOT NULL DEFAULT 0,
  quiz_done BIT NOT NULL DEFAULT 0,
  reflected BIT NOT NULL DEFAULT 0,
  reflection_text NVARCHAR(MAX) NULL,
  yn_answer NVARCHAR(10) NULL,
  CONSTRAINT UQ_daily_progress_uid_date UNIQUE (uid, progress_date),
  CONSTRAINT FK_daily_progress_users FOREIGN KEY (uid) REFERENCES dbo.users(uid) ON DELETE CASCADE
);
GO

CREATE TABLE dbo.xp_log (
  id INT IDENTITY(1,1) PRIMARY KEY,
  uid NVARCHAR(40) NOT NULL,
  amount INT NOT NULL,
  reason NVARCHAR(100) NULL,
  earned_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
  CONSTRAINT FK_xp_log_users FOREIGN KEY (uid) REFERENCES dbo.users(uid) ON DELETE CASCADE
);
GO

CREATE TABLE dbo.sessions (
  token NVARCHAR(128) PRIMARY KEY,
  uid NVARCHAR(40) NOT NULL,
  created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
  expires_at DATETIME2 NOT NULL,
  CONSTRAINT FK_sessions_users FOREIGN KEY (uid) REFERENCES dbo.users(uid) ON DELETE CASCADE
);
GO

IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE uid = 'd1')
INSERT INTO dbo.users (uid, name, email, phone, state, pass_hash, xp, streak)
VALUES ('d1', 'Priya M.', 'priya@demo.com', '9876543210', 'Maharashtra', 'demo', 345, 12);

IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE uid = 'd2')
INSERT INTO dbo.users (uid, name, email, phone, state, pass_hash, xp, streak)
VALUES ('d2', 'Arjun S.', 'arjun@demo.com', '9876543211', 'Delhi', 'demo', 280, 9);

IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE uid = 'd3')
INSERT INTO dbo.users (uid, name, email, phone, state, pass_hash, xp, streak)
VALUES ('d3', 'Kavya R.', 'kavya@demo.com', '9876543212', 'Karnataka', 'demo', 210, 7);

IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE uid = 'd4')
INSERT INTO dbo.users (uid, name, email, phone, state, pass_hash, xp, streak)
VALUES ('d4', 'Ravi K.', 'ravi@demo.com', '9876543213', 'Tamil Nadu', 'demo', 150, 5);

IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE uid = 'd5')
INSERT INTO dbo.users (uid, name, email, phone, state, pass_hash, xp, streak)
VALUES ('d5', 'Anita D.', 'anita@demo.com', '9876543214', 'Gujarat', 'demo', 90, 3);
GO

IF NOT EXISTS (SELECT 1 FROM dbo.user_badges WHERE uid = 'd1' AND badge_id = 'beginner')
INSERT INTO dbo.user_badges (uid, badge_id) VALUES ('d1', 'beginner');
IF NOT EXISTS (SELECT 1 FROM dbo.user_badges WHERE uid = 'd1' AND badge_id = 'aware')
INSERT INTO dbo.user_badges (uid, badge_id) VALUES ('d1', 'aware');
IF NOT EXISTS (SELECT 1 FROM dbo.user_badges WHERE uid = 'd1' AND badge_id = 'nation_builder')
INSERT INTO dbo.user_badges (uid, badge_id) VALUES ('d1', 'nation_builder');

IF NOT EXISTS (SELECT 1 FROM dbo.user_badges WHERE uid = 'd2' AND badge_id = 'beginner')
INSERT INTO dbo.user_badges (uid, badge_id) VALUES ('d2', 'beginner');
IF NOT EXISTS (SELECT 1 FROM dbo.user_badges WHERE uid = 'd2' AND badge_id = 'aware')
INSERT INTO dbo.user_badges (uid, badge_id) VALUES ('d2', 'aware');
IF NOT EXISTS (SELECT 1 FROM dbo.user_badges WHERE uid = 'd2' AND badge_id = 'nation_builder')
INSERT INTO dbo.user_badges (uid, badge_id) VALUES ('d2', 'nation_builder');

IF NOT EXISTS (SELECT 1 FROM dbo.user_badges WHERE uid = 'd3' AND badge_id = 'beginner')
INSERT INTO dbo.user_badges (uid, badge_id) VALUES ('d3', 'beginner');
IF NOT EXISTS (SELECT 1 FROM dbo.user_badges WHERE uid = 'd3' AND badge_id = 'aware')
INSERT INTO dbo.user_badges (uid, badge_id) VALUES ('d3', 'aware');
IF NOT EXISTS (SELECT 1 FROM dbo.user_badges WHERE uid = 'd3' AND badge_id = 'nation_builder')
INSERT INTO dbo.user_badges (uid, badge_id) VALUES ('d3', 'nation_builder');

IF NOT EXISTS (SELECT 1 FROM dbo.user_badges WHERE uid = 'd4' AND badge_id = 'beginner')
INSERT INTO dbo.user_badges (uid, badge_id) VALUES ('d4', 'beginner');
IF NOT EXISTS (SELECT 1 FROM dbo.user_badges WHERE uid = 'd4' AND badge_id = 'aware')
INSERT INTO dbo.user_badges (uid, badge_id) VALUES ('d4', 'aware');

IF NOT EXISTS (SELECT 1 FROM dbo.user_badges WHERE uid = 'd5' AND badge_id = 'beginner')
INSERT INTO dbo.user_badges (uid, badge_id) VALUES ('d5', 'beginner');
GO
