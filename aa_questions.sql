PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS question_follows;
DROP TABLE IF EXISTS replies;
DROP TABLE IF EXISTS question_likes;
DROP TABLE IF EXISTS questions;
DROP TABLE IF EXISTS users;


CREATE TABLE users (
  id      INTEGER PRIMARY KEY,
  fname   VARCHAR(255) NOT NULL,
  lname   VARCHAR(255) NOT NULL
);

CREATE TABLE questions (
  id      INTEGER PRIMARY KEY,
  title   VARCHAR(255) NOT NULL,
  body    TEXT,
  user_id INTEGER NOT NULL,
  FOREIGN KEY(user_id) REFERENCES users(id)
);

CREATE TABLE question_follows (
  user_id      INTEGER NOT NULL,
  question_id  INTEGER NOT NULL,
  FOREIGN KEY(user_id)      REFERENCES users(id),
  FOREIGN KEY(question_id)  REFERENCES questions(id)
);

CREATE TABLE replies (
  id              INTEGER PRIMARY KEY,
  question_id     INTEGER NOT NULL,
  parent_id       INTEGER,
  user_id         INTEGER NOT NULL,
  body            TEXT,
  FOREIGN KEY(question_id)  REFERENCES questions(id),
  FOREIGN KEY(parent_id)    REFERENCES replies(id),
  FOREIGN KEY(user_id)      REFERENCES users(id)
);

CREATE TABLE question_likes (
  user_id         INTEGER NOT NULL,
  question_id     INTEGER NOT NULL,
  FOREIGN KEY(user_id) REFERENCES users(id),
  FOREIGN KEY(question_id) REFERENCES questions(id)
);

INSERT INTO
  users (fname, lname)
VALUES
  ('Rikey', 'Chen'),
  ('Josh', 'Stroud'),
  ('Bruce', 'Wayne');

INSERT INTO
  questions (title, body, user_id)
VALUES
  ('How old am I?', 'I am exactly 42 years old', 1),
  ('What is the meaning of life?', '42', 2),
  ('How do we save Gotham City?', 'With Batman and heavy power tools.', 3);

INSERT INTO
  question_follows (user_id, question_id)
VALUES
  (1, 1),
  (2, 2),
  (3, 3),
  (2, 1),
  (2, 3),
  (1, 3);

INSERT INTO
  replies (question_id, parent_id, user_id, body)
VALUES
  (1, NULL, 2, 'You are definitely not 42 years old.'),
  (2, 1, 1, 'Yes I am.'),
  (2, NULL, 3, 'The meaning of life is catching villains.'),
  (3, NULL, 1, 'Sausages.'),
  (3, 4, 3, 'Batman does not eat sausages, he lives to fight crime.');

INSERT INTO
  question_likes (user_id, question_id)
VALUES
  (1, 1),
  (2, 2),
  (3, 3),
  (1, 3),
  (2, 3);
