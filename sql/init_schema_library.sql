---
-- LIBRARY SCHEMA
---
DROP TABLE transactions;
DROP TABLE books;
DROP TABLE patrons;
DROP TABLE authors;
DROP TABLE library CASCADE CONSTRAINTS;
DROP TABLE locations CASCADE CONSTRAINTS;

-- Create tables
CREATE TABLE locations (
  location_id NUMBER PRIMARY KEY,
  city VARCHAR2(30),
  state VARCHAR2(30),
  zip_code VARCHAR2(10),
  CONSTRAINT unique_location UNIQUE (city, state, zip_code)
);

CREATE TABLE library (
  library_id NUMBER PRIMARY KEY,
  name VARCHAR2(30),
  location_id NUMBER REFERENCES locations(location_id)
);

CREATE TABLE authors (
  author_id NUMBER PRIMARY KEY,
  last_name VARCHAR2(30) NOT NULL,
  first_name VARCHAR2(30),
  birthdate DATE
);

CREATE TABLE books (
  book_id VARCHAR2(20) PRIMARY KEY,
  title VARCHAR2(50) NOT NULL,
  author_id NUMBER REFERENCES authors(author_id),
  rating NUMBER,
  CONSTRAINT rating_1_to_10 CHECK (rating IS NULL OR (rating >= 1 AND rating <= 10))
);

CREATE TABLE patrons (
  patron_id NUMBER PRIMARY KEY,
  last_name VARCHAR2(30) NOT NULL,
  first_name VARCHAR2(30),
  street_address VARCHAR2(50),
  location_id NUMBER REFERENCES locations(location_id)
);

CREATE TABLE transactions (
  transaction_id NUMBER PRIMARY KEY,
  patron_id NUMBER REFERENCES patrons(patron_id),
  book_id VARCHAR2(20) REFERENCES books(book_id),
  transaction_date DATE NOT NULL,
  transaction_type NUMBER NOT NULL,
  costs NUMBER NOT NULL,
  duration NUMBER,
  library_id NUMBER REFERENCES library(library_id) NOT NULL
);

INSERT INTO locations (location_id, city, state, zip_code) VALUES (1, 'Enns', 'Upper Austria', '4470');
INSERT INTO locations (location_id, city, state, zip_code) VALUES (2, 'Leonding', 'Upper Austria', '4060');
INSERT INTO locations (location_id, city, state, zip_code) VALUES (3, 'Mytown', 'MA', '01234');
INSERT INTO locations (location_id, city, state, zip_code) VALUES (4, 'Sometown', 'NH', '03078');

INSERT INTO library VALUES (1, 'Stadtbibliothek', 1);
INSERT INTO library VALUES (2, 'Schulbibliothek HTL', 2);
INSERT INTO library VALUES (3, 'Pfarrbibliothek', 1);

INSERT INTO authors (author_id, last_name, first_name, birthdate) VALUES (1, 'Melville', 'Herman', TO_DATE('1819-08-01', 'YYYY-MM-DD'));
INSERT INTO authors (author_id, last_name, first_name, birthdate) VALUES (2, 'Scammer', 'Ima', NULL);
INSERT INTO authors (author_id, last_name, first_name, birthdate) VALUES (3, 'Blissford', 'Serenity', NULL);
INSERT INTO authors (author_id, last_name, first_name, birthdate) VALUES (4, 'Whodunit', 'Rodney', NULL);
INSERT INTO authors (author_id, last_name, first_name, birthdate) VALUES (5, 'Abugov', 'D.', NULL);

INSERT INTO books (book_id, title, author_id, rating) VALUES ('A1111', 'Moby Dick', 1, 10);
INSERT INTO books (book_id, title, author_id, rating) VALUES ('A2222', 'Get Rich Really Fast', 2, 1);
INSERT INTO books (book_id, title, author_id, rating) VALUES ('A3333', 'Finding Inner Peace', 3, NULL);
INSERT INTO books (book_id, title, author_id, rating) VALUES ('A4444', 'Great Mystery Stories', 4, 5);
INSERT INTO books (book_id, title, author_id, rating) VALUES ('A5555', 'Software Wizardry', 5, 10);

INSERT INTO patrons (patron_id, last_name, first_name, street_address, location_id) VALUES (100, 'Smith', 'Jane', '123 Main Street', 3);
INSERT INTO patrons (patron_id, last_name, first_name, street_address, location_id) VALUES (101, 'Chen', 'William', '16 S. Maple Road', 3);
INSERT INTO patrons (patron_id, last_name, first_name, street_address, location_id) VALUES (102, 'Fernandez', 'Maria', '502 Harrison Blvd.', 4);
INSERT INTO patrons (patron_id, last_name, first_name, street_address, location_id) VALUES (103, 'Murphy', 'Sam', '57 Main Street', 3);

INSERT INTO transactions VALUES (1, 100, 'A1111', TO_DATE('2015/05/15', 'YYYY/MM/DD'), 1, 6, 20, 1);
INSERT INTO transactions VALUES (2, 100, 'A2222', TO_DATE('2015/06/12', 'YYYY/MM/DD'), 2, 2, 5, 2);
INSERT INTO transactions VALUES (3, 101, 'A3333', TO_DATE('2015/07/01', 'YYYY/MM/DD'), 3, 8, 8, 2);
INSERT INTO transactions VALUES (4, 101, 'A2222', TO_DATE('2016/01/01', 'YYYY/MM/DD'), 1, 10, 20, 3);
INSERT INTO transactions VALUES (5, 102, 'A3333', TO_DATE('2016/07/01', 'YYYY/MM/DD'), 1, 1, 1, 3);
INSERT INTO transactions VALUES (6, 103, 'A4444', TO_DATE('2018/07/01', 'YYYY/MM/DD'), 2, 2, 2, 2);
INSERT INTO transactions VALUES (7, 100, 'A4444', TO_DATE('2018/07/02', 'YYYY/MM/DD'), 1, 10, 31, 1);
INSERT INTO transactions VALUES (8, 102, 'A2222', TO_DATE('2018/07/03', 'YYYY/MM/DD'), 2, 5, 45, 1);
INSERT INTO transactions VALUES (9, 102, 'A5555', TO_DATE('2019/01/01', 'YYYY/MM/DD'), 1, 7, NULL, 2);
INSERT INTO transactions VALUES (10, 101, 'A2222', TO_DATE('2019/01/02', 'YYYY/MM/DD'), 1, 9, NULL, 3);
