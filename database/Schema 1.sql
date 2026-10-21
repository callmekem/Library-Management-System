CREATE DATABASE IF NOT EXISTS library_system
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE library_system;

SET FOREIGN_KEY_CHECKS = 0;
DROP TRIGGER IF EXISTS trg_before_loan_tx_insert_check_member;
DROP TRIGGER IF EXISTS trg_before_loan_detail_insert_check_copy;
DROP TRIGGER IF EXISTS trig_before_loan_detail_insert_check_copy;
DROP TABLE IF EXISTS Loan_Detail, Loan_Transaction, Reservation, Book_Copy,
  Book_Author, Author, Book, Category, Publisher, Staff,
  Member_Phone, Member, Member_Category;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE Publisher (
  Publisher_ID   VARCHAR(50)  NOT NULL,
  Publisher_Name VARCHAR(150) NOT NULL,
  Address        VARCHAR(255) NULL,
  Contact_Email  VARCHAR(100) NULL,
  PRIMARY KEY (Publisher_ID),
  CONSTRAINT uq_publisher_name UNIQUE (Publisher_Name)
);

CREATE TABLE Category (
  Category_ID   VARCHAR(50)  NOT NULL,
  Category_Name VARCHAR(100) NOT NULL,
  Description   TEXT         NULL,
  PRIMARY KEY (Category_ID),
  CONSTRAINT uq_category_name UNIQUE (Category_Name)
);

CREATE TABLE Book (
  Book_ID          VARCHAR(50)  NOT NULL,
  Category_ID      VARCHAR(50)  NULL,
  Publisher_ID     VARCHAR(50)  NULL,
  ISBN             VARCHAR(50)  NOT NULL,
  Title            VARCHAR(255) NOT NULL,
  Publication_Year INT          NULL,
  PRIMARY KEY (Book_ID),
  CONSTRAINT uq_book_isbn UNIQUE (ISBN),
  CONSTRAINT chk_book_pub_year CHECK (Publication_Year BETWEEN 1 AND 2100),
  CONSTRAINT fk_book_category FOREIGN KEY (Category_ID)
    REFERENCES Category (Category_ID) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_book_publisher FOREIGN KEY (Publisher_ID)
    REFERENCES Publisher (Publisher_ID) ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE TABLE Author (
  Author_ID   VARCHAR(50)  NOT NULL,
  Author_Name VARCHAR(150) NOT NULL,
  Biography   TEXT         NULL,
  PRIMARY KEY (Author_ID)
);

CREATE TABLE Book_Author (
  Book_ID      VARCHAR(50) NOT NULL,
  Author_ID    VARCHAR(50) NOT NULL,
  Author_Order INT         NOT NULL,
  PRIMARY KEY (Book_ID, Author_ID),
  CONSTRAINT uq_book_author_order UNIQUE (Book_ID, Author_Order),
  CONSTRAINT chk_author_order CHECK (Author_Order >= 1),
  CONSTRAINT fk_ba_book FOREIGN KEY (Book_ID)
    REFERENCES Book (Book_ID) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_ba_author FOREIGN KEY (Author_ID)
    REFERENCES Author (Author_ID) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Book_Copy (
  Book_ID         VARCHAR(50)  NOT NULL,
  Copy_ID         VARCHAR(50)  NOT NULL,
  Shelf_Location  VARCHAR(100) NULL,
  Status          VARCHAR(50)  NOT NULL DEFAULT 'Available',
  Condition_Notes TEXT         NULL,
  PRIMARY KEY (Book_ID, Copy_ID),
  CONSTRAINT chk_book_copy_status
    CHECK (Status IN ('Available', 'Borrowed', 'Reserved', 'Damaged', 'Lost')),
  CONSTRAINT fk_copy_book FOREIGN KEY (Book_ID)
    REFERENCES Book (Book_ID) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Reservation (
  Reservation_ID   VARCHAR(50) NOT NULL,
  Member_ID        VARCHAR(50) NOT NULL,
  Book_ID          VARCHAR(50) NOT NULL,
  Reservation_Date DATE        NOT NULL,
  Status           VARCHAR(50) NOT NULL DEFAULT 'Pending',
  PRIMARY KEY (Reservation_ID),
  CONSTRAINT chk_reservation_status
    CHECK (Status IN ('Pending', 'Confirmed', 'Completed', 'Cancelled')),
  CONSTRAINT fk_res_book FOREIGN KEY (Book_ID)
    REFERENCES Book (Book_ID) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_res_member FOREIGN KEY (Member_ID)
    REFERENCES Member (Member_ID) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX idx_book_title       ON Book (Title);
CREATE INDEX idx_book_copy_status ON Book_Copy (Status);
CREATE INDEX idx_author_name      ON Author (Author_Name);
