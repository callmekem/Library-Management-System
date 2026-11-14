

-- PROJECT:     Topic 22 - Library Management System
-- DBMS:        MySQL 8.4 LTS | Tool: MySQL Workbench
-- MySQL-specific parts: ENGINE=InnoDB, the expression default
--   DEFAULT (CURRENT_DATE), DELIMITER and the trigger syntax (DECLARE,
--   SIGNAL SQLSTATE '45000'), and DATEDIFF and GREATEST in the views.
 
 
 
SET NAMES utf8mb4;
SET SESSION sql_mode = 'STRICT_ALL_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
 
DROP DATABASE IF EXISTS library_management_db;
CREATE DATABASE library_management_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
 
USE library_management_db;
 
 
-- 1. BR01: A physical book copy (Book_Copy) cannot exist independently without being associated with a parent book title (Book).
-- 2. BR02: Book reservations (Reservation) are placed on a specific Book (title), whereas active loans (Loan_Detail) are tracked by physical book copies (Book_Copy).
-- 3. BR03: Member borrowing privileges (limits and loan durations) are strictly 
--    governed by their membership category (Member_Category).
-- 4. BR04: Staff members operate under an organizational hierarchy where a
--    staff member may report to a designated supervisor (Staff self-reference).
-- 5. BR05: Overdue books incur fines which are tracked for each specific
--    borrowed copy in the Loan_Detail table, along with their payment statuses.

--         Where each rule is enforced
--   BR01  Book_Copy.Book_ID NOT NULL, PK (Book_ID, Copy_ID),
--         FK fk_copy_book ON DELETE CASCADE (copies go with their title)
--   BR02  Reservation: FK fk_res_book (title level, no copy column);
--         Loan_Detail: composite FK FK_loandetail_borrowed_BookCopy (copy level);
--         Triggers 2 and 3 (a copy is on at most one open loan line)
--   Dates Triggers 2 and 3 (Return_Date is not before Borrow_Date)
--   BR03  Member.Member_Type_ID NOT NULL + FK; CHECK check_MemberCategoryLimit;
--         Trigger 1 (status, expiry, loan period and limit at checkout),
--         Trigger 2 (limit on the copies really out),
--         Trigger 3 (loan line re-opened or moved)
--   BR04  FK FK_staffSupervisor (NULL = top of the hierarchy);
--         Triggers 4 and 5 (nobody supervises themself)
--   BR05  Payment_Status in every Loan_Detail row; CHECK
--         check_loandetail_paymentstatus; Fine_Amount from view Loan_Detail_Fine;
--         Triggers 2 and 3 (a copy returned late carries a fine)
--
--   Derived attributes (dashed ellipses in the ER diagram) are not stored
--   as columns, because their value can be computed from other data:
--     Loan_Transaction.Total_Copies_Borrowed -> view Loan_Summary
--     Loan_Detail.Fine_Amount                -> view Loan_Detail_Fine
--                                               (5,000 VND per day late)
 
 
 
 
-- table 1 
-- Enforces BR03: Defines borrowing limits and loan durations per membership tier

CREATE TABLE Member_Category (
    Member_Type_ID  VARCHAR(20) NOT NULL,
    Type_Name       VARCHAR(50) NOT NULL,
    Borrowing_Limit INT         NOT NULL DEFAULT 3,
    Loan_Period     INT         NOT NULL DEFAULT 7,
    CONSTRAINT PK_Member_Category
        PRIMARY KEY (Member_Type_ID),
    CONSTRAINT unique_Member_Category_TypeName
        UNIQUE (Type_Name),
    CONSTRAINT check_MemberCategoryLimit
        CHECK (Borrowing_Limit BETWEEN 1 AND 20  AND Loan_Period BETWEEN 7 AND 20) -- each Member category can borrow difference limit and difference loan
) ENGINE=InnoDB;
 
-- table 2  Member
-- Enforces BR03: Every member belongs to a valid Member_Category
 
CREATE TABLE Member (
    Member_ID              VARCHAR(20)  NOT NULL,
    Member_Type_ID         VARCHAR(20)  NOT NULL,
    Full_Name              VARCHAR(100) NOT NULL,
    Email                  VARCHAR(200) NOT NULL,
    Identity_Card          VARCHAR(20)  NOT NULL,
    Membership_Expiry_Date DATE         NOT NULL,
    Account_Status         VARCHAR(20)  NOT NULL DEFAULT 'Active',
    CONSTRAINT PK_Member
        PRIMARY KEY (Member_ID),
    CONSTRAINT unique_MemberEmail
        UNIQUE (Email),
    CONSTRAINT unique_MemberIdentityCard
        UNIQUE (Identity_Card),
    CONSTRAINT FK_Memberbelongto_category
        FOREIGN KEY (Member_Type_ID)
        REFERENCES Member_Category (Member_Type_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT check_Emailformat
        CHECK (Email LIKE '%_@__%.__%'),
    CONSTRAINT check_Member_IdentityCard_Len
        CHECK (CHAR_LENGTH(Identity_Card) BETWEEN 9 AND 20),
    CONSTRAINT check_Member_AccountStatus
        CHECK (Account_Status IN ('Active', 'Suspended', 'Expired', 'Locked'))
) ENGINE=InnoDB;
 
 
-- table 3 Member_Phone
-- Resolves multivalued attribute Phone of Member (1NF)
 
CREATE TABLE Member_Phone (
    Member_ID VARCHAR(20) NOT NULL,
    Phone     VARCHAR(20) NOT NULL,
    CONSTRAINT pk_member_phone
        PRIMARY KEY (Member_ID, Phone),
    CONSTRAINT fk_member_phone_has_phone
        FOREIGN KEY (Member_ID)
        REFERENCES Member (Member_ID)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT check_Memberphonelength
        CHECK (CHAR_LENGTH(Phone) BETWEEN 8 AND 20)
) ENGINE=InnoDB;
 
 
-- Table 4  Category
-- Book subject classification catalogue
 
CREATE TABLE Category (
    Category_ID   VARCHAR(20)  NOT NULL,
    Category_Name VARCHAR(100) NOT NULL,
    Description   TEXT         NULL,  -- describe the book 
    CONSTRAINT pk_category
        PRIMARY KEY (Category_ID),
    CONSTRAINT uq_category_name
        UNIQUE (Category_Name),
    --  Every table carries a CHECK : a category needs a name.
    CONSTRAINT chk_category_name_not_blank
        CHECK (CHAR_LENGTH(TRIM(Category_Name)) > 0) -- Not null is not enough because ' ' is also not null so we need to check 
) ENGINE=InnoDB;
 
 
-- table 5  Publisher
-- Book publishing house master table
 
CREATE TABLE Publisher (
    Publisher_ID   VARCHAR(20)  NOT NULL,
    Publisher_Name VARCHAR(150) NOT NULL,
    Address        VARCHAR(255) ,
    Contact_Email  VARCHAR(100) ,
    CONSTRAINT pk_publisher
        PRIMARY KEY (Publisher_ID),
    CONSTRAINT uq_publisher_name
        UNIQUE (Publisher_Name),
    CONSTRAINT uq_publisher_contact_email
        UNIQUE (Contact_Email),
    CONSTRAINT chk_publisher_email_format
        CHECK (Contact_Email IS NULL OR Contact_Email LIKE '%_@__%.__%')
) ENGINE=InnoDB;
 
 
-- table 6  Author
-- Book author master table
 
CREATE TABLE Author (
    Author_ID   VARCHAR(20)  NOT NULL,
    Author_Name VARCHAR(150) NOT NULL, 
    Biography   TEXT         NULL,
    CONSTRAINT pk_author
        PRIMARY KEY (Author_ID),
        -- author name is not unique because some author may share the name
    CONSTRAINT chk_author_name_not_blank
        CHECK (CHAR_LENGTH(TRIM(Author_Name)) > 0)
) ENGINE=InnoDB;
 
-- table 7  Book
-- Catalogue book title with ISBN, Title, Publication_Year, Category, Publisher
 
CREATE TABLE Book (
    Book_ID          VARCHAR(20)  NOT NULL,
    Category_ID      VARCHAR(20)  NOT NULL,
    Publisher_ID     VARCHAR(20)  NOT NULL,
    ISBN             VARCHAR(20)  NOT NULL,
    Title            VARCHAR(255) NOT NULL,
    Publication_Year INT          NOT NULL,
    CONSTRAINT pk_book
        PRIMARY KEY (Book_ID),
    CONSTRAINT uq_book_isbn
        UNIQUE (ISBN),
    CONSTRAINT chk_book_pub_year
        CHECK (Publication_Year BETWEEN 1450 AND 2100),
    CONSTRAINT chk_book_isbn_length 
        CHECK (CHAR_LENGTH(ISBN) BETWEEN 10 AND 20),
    CONSTRAINT fk_book_category
        FOREIGN KEY (Category_ID)
        REFERENCES Category (Category_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_book_publisher
        FOREIGN KEY (Publisher_ID)
        REFERENCES Publisher (Publisher_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;
 
 
-- table 8  Book_Author
-- Resolves M:N relationship Written_By carrying attribute Author_Order
 
CREATE TABLE Book_Author (
    Book_ID      VARCHAR(20) NOT NULL,
    Author_ID    VARCHAR(20) NOT NULL,
    Author_Order INT         NOT NULL DEFAULT 1,
    CONSTRAINT pk_book_author
        PRIMARY KEY (Book_ID, Author_ID),
    CONSTRAINT uq_book_author_order
        UNIQUE (Book_ID, Author_Order),
    CONSTRAINT chk_author_order
        CHECK (Author_Order >= 1),
    CONSTRAINT fk_ba_book
        FOREIGN KEY (Book_ID)
        REFERENCES Book (Book_ID)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_ba_author
        FOREIGN KEY (Author_ID)
        REFERENCES Author (Author_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;
 
 
-- table 9  Staff
-- Enforces BR04: Organizational hierarchy via recursive self-referencing FK
 
CREATE TABLE Staff (
    Staff_ID      VARCHAR(20)  NOT NULL,
    Supervisor_ID VARCHAR(20)  NULL DEFAULT NULL,
    Full_Name     VARCHAR(100) NOT NULL,
    Position      VARCHAR(50)  NOT NULL DEFAULT 'Librarian',
    Email         VARCHAR(200) NOT NULL,
    CONSTRAINT PK_Staff
        PRIMARY KEY (Staff_ID),
    CONSTRAINT unique_staffemail
        UNIQUE (Email),
 
    CONSTRAINT FK_staffSupervisor
        FOREIGN KEY (Supervisor_ID)
        REFERENCES Staff (Staff_ID)
        ON DELETE SET NULL
        ON UPDATE RESTRICT,
    CONSTRAINT check_staffemailformat
        CHECK (Email LIKE '%_@__%.__%')
) ENGINE=InnoDB;
 
-- Table 10 Loan_Transaction
-- Header table for a borrowing transaction handled by a Staff member
-- Total_Copies_Borrowed is a derived attribute in the ER diagram: it is not
-- stored here, the view Loan_Summary counts the loan lines instead.
 
CREATE TABLE Loan_Transaction (
    Loan_ID               VARCHAR(20) NOT NULL,
    Member_ID             VARCHAR(20) NOT NULL,
    Staff_ID              VARCHAR(20) NOT NULL,
    Borrow_Date           DATE        NOT NULL DEFAULT (CURRENT_DATE),
    Due_Date              DATE        NOT NULL,
    CONSTRAINT PK_Loantransaction
        PRIMARY KEY (Loan_ID),
    CONSTRAINT FK_loantransactionMakeMember
        FOREIGN KEY (Member_ID)
        REFERENCES Member (Member_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT FK_loanhandlesStaffID
        FOREIGN KEY (Staff_ID)
        REFERENCES Staff (Staff_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT check_loantransactionDate
        CHECK (Due_Date >= Borrow_Date)
) ENGINE=InnoDB;
 
 
-- table 11  Book_Copy (Weak Entity Set)
-- Enforces BR01: Identified by composite key (Book_ID, Copy_ID)
 
CREATE TABLE Book_Copy (
    Book_ID         VARCHAR(20)  NOT NULL,
    Copy_ID         VARCHAR(20)  NOT NULL,
    Shelf_Location  VARCHAR(100) NOT NULL,
    Status          VARCHAR(20)  NOT NULL DEFAULT 'Available',
    Condition_Notes TEXT         NULL,
    CONSTRAINT pk_book_copy
        PRIMARY KEY (Book_ID, Copy_ID),
    CONSTRAINT chk_book_copy_status
        CHECK (Status IN ('Available', 'Borrowed', 'Reserved', 'Damaged', 'Lost')),
    CONSTRAINT fk_copy_book
        FOREIGN KEY (Book_ID)
        REFERENCES Book (Book_ID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB;
 
 
-- table 12  Reservation
-- Enforces BR02: Reservations reference Book_ID (title level), whereas loans
-- (Loan_Detail) reference a physical copy. A member waits for "any copy of
-- this title", so the reservation cannot name a copy. Reserving only a
-- title that is fully on loan is checked by the Java application.
 
CREATE TABLE Reservation (
    Reservation_ID   VARCHAR(20) NOT NULL,
    Member_ID        VARCHAR(20) NOT NULL,
    Book_ID          VARCHAR(20) NOT NULL,
    Reservation_Date DATE        NOT NULL DEFAULT (CURRENT_DATE),
    Status           VARCHAR(20) NOT NULL DEFAULT 'Pending',
    CONSTRAINT pk_reservation
        PRIMARY KEY (Reservation_ID),
    CONSTRAINT chk_reservation_status
        CHECK (Status IN ('Pending', 'Confirmed', 'Completed', 'Cancelled')),
    CONSTRAINT fk_res_book
        FOREIGN KEY (Book_ID)
        REFERENCES Book (Book_ID)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_res_member
        FOREIGN KEY (Member_ID)
        REFERENCES Member (Member_ID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB;
 
 
-- table 13  Loan_Detail (Weak Entity Set)
-- Enforces BR02 & BR05: Links to physical copy (Book_ID, Copy_ID) & tracks fines
-- Fine_Amount is a derived attribute in the ER diagram: it is not stored
-- here, the view Loan_Detail_Fine computes it.
 
CREATE TABLE Loan_Detail (
    Loan_ID        VARCHAR(20)    NOT NULL,
    Detail_ID      VARCHAR(20)    NOT NULL,
    Book_ID        VARCHAR(20)    NOT NULL,
    Copy_ID        VARCHAR(20)    NOT NULL,
    Return_Date    DATE           NULL DEFAULT NULL,
    Renewal_Count  INT            NOT NULL DEFAULT 0,
    Payment_Status VARCHAR(20)    NOT NULL DEFAULT 'None',
    CONSTRAINT PK_LoanDetail
        PRIMARY KEY (Loan_ID, Detail_ID),
    CONSTRAINT FK_loanDetail_belongto_loanID
        FOREIGN KEY (Loan_ID)
        REFERENCES Loan_Transaction (Loan_ID)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT unique_loandetail_copy_per_loan
        UNIQUE (Loan_ID, Book_ID, Copy_ID),
    CONSTRAINT FK_loandetail_borrowed_BookCopy
        FOREIGN KEY (Book_ID, Copy_ID)
        REFERENCES Book_Copy (Book_ID, Copy_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT check_loandetail_renewalcount
        CHECK (Renewal_Count BETWEEN 0 AND 5),
    CONSTRAINT check_loandetail_paymentstatus
        CHECK (Payment_Status IN ('None', 'Unpaid', 'Paid', 'Waived'))
) ENGINE=InnoDB;
 
 
-- Indexes: each one names the Topic 22 query it helps
-- Circulation and fines
CREATE INDEX index_loanTransaction_member_due ON Loan_Transaction (Member_ID, Due_Date);    -- Q2 loans of one member overdue today
CREATE INDEX idx_loan_detail_return_date      ON Loan_Detail (Return_Date);                 -- Q2 copies not returned (Return_Date IS NULL)
CREATE INDEX idx_loantransaction_borrow_date  ON Loan_Transaction (Borrow_Date);            -- Q3 ten most borrowed titles this year (year as a date range)
CREATE INDEX idx_loan_detail_payment_status   ON Loan_Detail (Payment_Status);               -- Q5 fines outstanding per member category
-- Catalogue and authors
CREATE INDEX idx_book_title                   ON Book (Title);                              -- Q1 find a title by name (prefix search)
CREATE INDEX idx_book_copy_status             ON Book_Copy (Book_ID, Status);               -- Q1 copies of a title currently available
CREATE INDEX idx_author_name                  ON Author (Author_Name);                      -- Q4 titles by a given author


-- Loan_Transaction.Total_Copies_Borrowed = number of lines of the loan
CREATE VIEW Loan_Summary AS
SELECT lt.Loan_ID,
       lt.Member_ID,
       lt.Staff_ID,
       lt.Borrow_Date,
       lt.Due_Date,
       COUNT(ld.Detail_ID) AS Total_Copies_Borrowed
FROM Loan_Transaction lt
LEFT JOIN Loan_Detail ld
    ON ld.Loan_ID = lt.Loan_ID
GROUP BY lt.Loan_ID, lt.Member_ID, lt.Staff_ID, lt.Borrow_Date, lt.Due_Date;

-- Loan_Detail.Fine_Amount = 5,000 VND for each day a copy is kept after its
-- due date, counted up to the return date (or up to today while the copy is
-- still out). A fine is outstanding while Fine_Amount > 0 and Payment_Status
-- is not 'Paid' or 'Waived'.

CREATE VIEW Loan_Detail_Fine AS
SELECT ld.Loan_ID,
       ld.Detail_ID,
       ld.Book_ID,
       ld.Copy_ID,
       lt.Member_ID,
       lt.Due_Date,
       ld.Return_Date,
       GREATEST(DATEDIFF(COALESCE(ld.Return_Date, CURRENT_DATE), lt.Due_Date), 0) AS Days_Late,
       GREATEST(DATEDIFF(COALESCE(ld.Return_Date, CURRENT_DATE), lt.Due_Date), 0) * 5000.00 AS Fine_Amount,
       ld.Payment_Status
FROM Loan_Detail ld
INNER JOIN Loan_Transaction lt
    ON lt.Loan_ID = ld.Loan_ID;
 
 
 
--  Member_Category (15 rows)
INSERT INTO Member_Category (Member_Type_ID, Type_Name, Borrowing_Limit, Loan_Period) VALUES
('MC01', 'Undergraduate Student', 5, 10),
('MC02', 'Postgraduate Student', 8, 15),
('MC03', 'Doctoral Researcher', 12, 20),
('MC04', 'Full-Time Lecturer', 15, 20),
('MC05', 'Visiting Scholar', 10, 18),
('MC06', 'Library Staff Member', 10, 20),
('MC07', 'Administrative Staff', 6, 20),
('MC08', 'Alumni Standard', 3, 7),
('MC09', 'Alumni Gold', 6, 12),
('MC10', 'Exchange Student', 4, 17),
('MC11', 'External Reader', 2, 7),
('MC12', 'High School Gifted Student', 3, 9),
('MC13', 'Corporate Partner', 8, 20),
('MC14', 'Retired Faculty', 10, 20),
('MC15', 'Honorary Fellow', 20, 19);
 
--  Member (15 rows)
INSERT INTO Member (Member_ID, Member_Type_ID, Full_Name, Email, Identity_Card, Membership_Expiry_Date, Account_Status) VALUES
('M01', 'MC01', 'Nguyen Van A', 'NVA@hcmiu.edu.vn', '079205001001', '2027-08-31', 'Active'),
('M02', 'MC02', 'Nguyen Van B', 'NVB@hcmiu.edu.vn', '079205001002', '2027-08-31', 'Active'),
('M03', 'MC03', 'Nguyen Van C', 'NVC@hcmiu.edu.vn', '079205001003', '2027-12-31', 'Active'),
('M04', 'MC01', 'Nguyen Van D', 'NVD@hcmiu.edu.vn', '079205001004', '2027-08-31', 'Active'),
('M05', 'MC04', 'Nguyen Van E', 'NVE@hcmiu.edu.vn', '079205001005', '2028-06-30', 'Active'),
('M06', 'MC05', 'Nguyen Van F', 'NVF@hcmiu.edu.vn', '079205001006', '2027-05-15', 'Active'),
('M07', 'MC01', 'Nguyen Van G', 'NVG@hcmiu.edu.vn', '079205001007', '2027-08-31', 'Active'),
('M08', 'MC02', 'Nguyen Van H', 'NVH@hcmiu.edu.vn', '079205001008', '2027-09-30', 'Active'),
('M09', 'MC08', 'Nguyen Van I', 'NVI@hcmiu.edu.vn', '079205001009', '2027-03-31', 'Suspended'),
('M10', 'MC04', 'Nguyen Van J', 'NVJ@hcmiu.edu.vn', '079205001010', '2028-12-31', 'Active'),
('M11', 'MC07', 'Nguyen Van K', 'NVK@hcmiu.edu.vn', '079205001011', '2027-10-31', 'Active'),
('M12', 'MC10', 'Nguyen Van L', 'NVL@hcmiu.edu.vn', '079205001012', '2027-01-31', 'Active'),
('M13', 'MC03', 'Nguyen Van M', 'NVM@hcmiu.edu.vn', '079205001013', '2027-11-30', 'Active'),
('M14', 'MC11', 'Nguyen Van N', 'NVN@gmail.com', '079205001014', '2026-04-30', 'Expired'),
('M15', 'MC09', 'Nguyen Van O', 'NVO@alumni.hcmiu.edu.vn', '079205001015', '2027-07-31', 'Locked');
 
-- Member_Phone (16 rows)
INSERT INTO Member_Phone (Member_ID, Phone) VALUES
('M01', '0901112201'),
('M01', '0988112201'),
('M02', '0901112202'),
('M02', '0913112202'),
('M03', '0901112203'),
('M04', '0901112204'),
('M05', '0901112205'),
('M06', '0901112206'),
('M07', '0901112207'),
('M08', '0901112208'),
('M09', '0901112209'),
('M10', '0901112210'),
('M11', '0901112211'),
('M12', '0901112212'),
('M13', '0901112213'),
('M14', '0901112214');
 
--  Category (15 rows)
INSERT INTO Category (Category_ID, Category_Name, Description) VALUES
('CAT01', 'Computer Science', 'Books related to computing, programming, and algorithms.'),
('CAT02', 'Mathematics', 'Calculus, algebra, geometry, and applied mathematics.'),
('CAT03', 'Physics', 'Quantum mechanics, thermodynamics, and classical physics.'),
('CAT04', 'Chemistry', 'Organic, inorganic, and physical chemistry.'),
('CAT05', 'Biology', 'Genetics, microbiology, and anatomy.'),
('CAT06', 'History', 'World history, ancient civilizations, and modern eras.'),
('CAT07', 'Geography', 'Physical geography, cartography, and earth sciences.'),
('CAT08', 'Philosophy', 'Ethics, logic, and ancient philosophical thoughts.'),
('CAT09', 'Psychology', 'Cognitive behavioral psychology and human minds.'),
('CAT10', 'Literature', 'Classic novels, poetry, and modern fiction.'),
('CAT11', 'Art & Design', 'Painting, graphic design, and architecture.'),
('CAT12', 'Music', 'Music theory, history, and instrumental guides.'),
('CAT13', 'Economics', 'Macroeconomics, microeconomics, and global markets.'),
('CAT14', 'Business & Management', 'Leadership, marketing, and corporate strategy.'),
('CAT15', 'Political Science', 'Government structures, international relations, and public policy.');
 
-- Publisher (15 rows)
INSERT INTO Publisher (Publisher_ID, Publisher_Name, Address, Contact_Email) VALUES
('PUB01', 'MIT Press', 'Cambridge, MA, USA', 'info@mitpress.mit.edu'),
('PUB02', 'Prentice Hall', 'Upper Saddle River, NJ, USA', 'contact@prenticehall.com'),
('PUB03', 'O''Reilly Media', 'Sebastopol, CA, USA', 'support@oreilly.com'),  -- real name; '' is one apostrophe
('PUB04', 'Springer', 'Berlin, Germany', 'customerservice@springer.com'),
('PUB05', 'Elsevier', 'Amsterdam, Netherlands', 'info@elsevier.com'),
('PUB06', 'Wiley', 'Hoboken, NJ, USA', 'info@wiley.com'),
('PUB07', 'McGraw-Hill', 'New York, NY, USA', 'support@mheducation.com'),
('PUB08', 'Pearson', 'London, UK', 'info@pearson.com'),
('PUB09', 'Cambridge University Press', 'Cambridge, UK', 'information@cambridge.org'),
('PUB10', 'Oxford University Press', 'Oxford, UK', 'enquiry@oup.com'),
('PUB11', 'HarperCollins', 'New York, NY, USA', 'feedback@harpercollins.com'),
('PUB12', 'Penguin Random House', 'New York, NY, USA', 'consumerservices@penguinrandomhouse.com'),
('PUB13', 'Simon & Schuster', 'New York, NY, USA', 'contact@simonandschuster.com'),
('PUB14', 'Macmillan', 'London, UK', 'contact@macmillan.com'),
('PUB15', 'Hachette Livre', 'Paris, France', 'contact@hachette.com');
 
-- Author (18 rows)
INSERT INTO Author (Author_ID, Author_Name, Biography) VALUES
('AUTH01', 'Thomas H. Cormen', 'Professor of computer science at Dartmouth College.'),
('AUTH02', 'Robert C. Martin', 'Software engineer, best-selling author, known as Uncle Bob.'),
('AUTH03', 'Martin Fowler', 'Software developer and author of books on software design.'),
('AUTH04', 'Donald Knuth', 'Computer scientist, author of The Art of Computer Programming.'),
('AUTH05', 'Alan Turing', 'Father of theoretical computer science and artificial intelligence.'),
('AUTH06', 'Isaac Newton', 'English mathematician, physicist, and astronomer.'),
('AUTH07', 'Albert Einstein', 'Theoretical physicist, developed the theory of relativity.'),
('AUTH08', 'Richard Feynman', 'American theoretical physicist known for quantum electrodynamics.'),
('AUTH09', 'Stephen Hawking', 'English theoretical physicist and cosmologist.'),
('AUTH10', 'Charles Darwin', 'English naturalist, geologist, and biologist.'),
('AUTH11', 'Sigmund Freud', 'Austrian neurologist and the founder of psychoanalysis.'),
('AUTH12', 'William Shakespeare', 'English playwright, poet, and actor.'),
('AUTH13', 'Jane Austen', 'English novelist known for her romantic fiction.'),
('AUTH14', 'Mark Twain', 'American writer, humorist, and essayist.'),
('AUTH15', 'George Orwell', 'English novelist, essayist, and critic.'),
('AUTH16', 'Charles E. Leiserson', 'Professor of computer science and engineering at MIT.'),
('AUTH17', 'Ronald L. Rivest', 'Cryptographer and professor at MIT, co-inventor of RSA.'),
('AUTH18', 'Clifford Stein', 'Professor of industrial engineering and computer science at Columbia University.');
 
-- Book (15 rows)
INSERT INTO Book (Book_ID, Category_ID, Publisher_ID, ISBN, Title, Publication_Year) VALUES
('B01', 'CAT01', 'PUB01', '978-0262033848', 'Introduction to Algorithms', 2009),
('B02', 'CAT01', 'PUB01', '978-0262524531', 'Algorithms Unlocked', 2013),
('B03', 'CAT01', 'PUB02', '978-0132350884', 'Clean Code', 2008),
('B04', 'CAT01', 'PUB03', '978-0201485677', 'Refactoring', 1999),
('B05', 'CAT01', 'PUB08', '978-0201896831', 'The Art of Computer Programming', 1968),
('B06', 'CAT02', 'PUB09', '978-0521446062', 'Mathematical Methods', 2006),
('B07', 'CAT03', 'PUB10', '978-0198520467', 'The Theory of Relativity', 1915),
('B08', 'CAT03', 'PUB06', '978-0465023627', 'The Feynman Lectures on Physics', 1964),
('B09', 'CAT03', 'PUB12', '978-0553380163', 'A Brief History of Time', 1988),
('B10', 'CAT05', 'PUB11', '978-0451529060', 'On the Origin of Species', 1859),
('B11', 'CAT09', 'PUB13', '978-0465097081', 'The Interpretation of Dreams', 1899),
('B12', 'CAT10', 'PUB14', '978-0743477109', 'Hamlet', 1603),
('B13', 'CAT10', 'PUB15', '978-0141439518', 'Pride and Prejudice', 1813),
('B14', 'CAT10', 'PUB11', '978-0486280615', 'The Adventures of Tom Sawyer', 1876),
('B15', 'CAT10', 'PUB12', '978-0451524935', '1984', 1949);
 
--  Book_Author (18 rows)
INSERT INTO Book_Author (Book_ID, Author_ID, Author_Order) VALUES
('B01', 'AUTH01', 1),
('B01', 'AUTH16', 2),
('B01', 'AUTH17', 3),
('B01', 'AUTH18', 4),
('B02', 'AUTH01', 1),
('B03', 'AUTH02', 1),
('B04', 'AUTH03', 1),
('B05', 'AUTH04', 1),
('B06', 'AUTH06', 1),
('B07', 'AUTH07', 1),
('B08', 'AUTH08', 1),
('B09', 'AUTH09', 1),
('B10', 'AUTH10', 1),
('B11', 'AUTH11', 1),
('B12', 'AUTH12', 1),
('B13', 'AUTH13', 1),
('B14', 'AUTH14', 1),
('B15', 'AUTH15', 1);
 
--  Staff (15 rows)
INSERT INTO Staff (Staff_ID, Supervisor_ID, Full_Name, Position, Email) VALUES
('S01', NULL,  'Dr. Nguyen Thi Minh Khai', 'Chief Librarian', 'ntmkhai@hcmiu.edu.vn'),
('S02', 'S01', 'Tran Van Quan', 'Deputy Chief Librarian', 'tvquan@hcmiu.edu.vn'),
('S03', 'S01', 'Le Thi Huong', 'Head of Circulation', 'lthuong@hcmiu.edu.vn'),
('S04', 'S01', 'Pham Quoc Tuan', 'Head of Cataloguing', 'pqtuan@hcmiu.edu.vn'),
('S05', 'S03', 'Hoang Minh Chau', 'Senior Circulation Librarian', 'hmchau@hcmiu.edu.vn'),
('S06', 'S03', 'Doan Van Hau', 'Circulation Librarian', 'dvhau@hcmiu.edu.vn'),
('S07', 'S03', 'Ngo Phuong Lan', 'Circulation Librarian', 'nplan@hcmiu.edu.vn'),
('S08', 'S03', 'Vuong Dinh Khoa', 'Circulation Desk Officer', 'vdkhoa@hcmiu.edu.vn'),
('S09', 'S03', 'Bui Thi Thanh', 'Circulation Desk Officer', 'btthanh@hcmiu.edu.vn'),
('S10', 'S02', 'Dang Quoc Viet', 'Reference Librarian', 'dqviet@hcmiu.edu.vn'),
('S11', 'S02', 'Ly Thanh Thao', 'Digital Archive Specialist', 'ltthao@hcmiu.edu.vn'),
('S12', 'S04', 'Trinh Cong Son', 'Senior Cataloguer', 'tcson@hcmiu.edu.vn'),
('S13', 'S04', 'Mai Phuong Thuy', 'Cataloguing Assistant', 'mpthuy@hcmiu.edu.vn'),
('S14', 'S04', 'Cao Thai Son', 'Acquisitions Specialist', 'ctson@hcmiu.edu.vn'),
('S15', 'S02', 'Huynh Thuc Khang', 'IT Systems Librarian', 'htkhang@hcmiu.edu.vn');
 
--  Loan_Transaction (15 rows)
-- Trigger 1 allows a Due_Date of at most Borrow_Date + the Loan_Period of the
-- member's category, and most loans below use that full period (MC01 10 days,
-- MC02 15, MC03 and MC04 20, MC05 18, MC08 7). L13 and L14 are shorter loans.
-- L12 was renewed once, which adds one more period (Renewal_Count in Loan_Detail).
 
INSERT INTO Loan_Transaction (Loan_ID, Member_ID, Staff_ID, Borrow_Date, Due_Date) VALUES
('L01', 'M01', 'S05', '2026-01-15', '2026-01-25'),
('L02', 'M02', 'S05', '2026-02-10', '2026-02-25'),
('L03', 'M01', 'S06', '2026-09-01', '2026-09-11'),
('L04', 'M03', 'S06', '2026-03-05', '2026-03-25'),
('L05', 'M04', 'S07', '2026-04-12', '2026-04-22'),
('L06', 'M01', 'S07', '2026-09-10', '2026-09-20'),
('L07', 'M05', 'S08', '2026-05-20', '2026-06-09'),
('L08', 'M06', 'S08', '2026-06-15', '2026-07-03'),
('L09', 'M07', 'S09', '2026-09-05', '2026-09-15'),
('L10', 'M08', 'S09', '2026-07-10', '2026-07-25'),
('L11', 'M09', 'S05', '2026-09-12', '2026-09-19'),  -- M09 was Active on 2026-09-12; suspended later for this overdue loan
('L12', 'M10', 'S06', '2026-08-01', '2026-09-10'),  -- 20 days, renewed once for 20 more
('L13', 'M11', 'S07', '2026-08-18', '2026-09-01'),
('L14', 'M12', 'S08', '2026-08-22', '2026-09-05'),
('L15', 'M13', 'S09', '2026-10-10', '2026-10-30');
 
-- Book_Copy (21 rows)
-- Condition_Notes record only the physical state of a copy, on one scale:
--   New      no wear                     Fair     visible wear (bent or worn cover)
--   Good     normal wear from use        Damaged  needs repair before it can be lent
--   Unknown  the copy is missing, so its state cannot be checked
-- Why a copy is Borrowed or Reserved is not written in the note: that comes
-- from Loan_Detail and Reservation (see the comment at the end of a line),
-- so the note stays true when the copy is returned.
 
INSERT INTO Book_Copy (Book_ID, Copy_ID, Shelf_Location, Status, Condition_Notes) VALUES
('B01', 'C01', 'Shelf A - Row 1', 'Available', 'Good'),
('B01', 'C02', 'Shelf A - Row 1', 'Available', 'New'),
('B02', 'C01', 'Shelf A - Row 2', 'Available', 'Fair: cover slightly bent'),
('B02', 'C02', 'Shelf A - Row 2', 'Borrowed',  'Good'),   -- out on loan L03
('B03', 'C01', 'Shelf B - Row 1', 'Reserved',  'Good'),   -- held at the desk for reservation RES07 (Confirmed)
('B03', 'C02', 'Shelf B - Row 1', 'Borrowed',  'Good'),   -- out on loan L03
('B04', 'C01', 'Shelf B - Row 2', 'Available', 'Good'),
('B04', 'C02', 'Shelf B - Row 2', 'Lost',      'Unknown: missing since 2025'),
('B05', 'C01', 'Shelf C - Row 1', 'Available', 'Good'),
('B06', 'C01', 'Shelf C - Row 2', 'Damaged',   'Damaged: torn pages, needs repair'),
('B06', 'C02', 'Shelf C - Row 2', 'Borrowed',  'Good'),   -- out on loan L06
('B07', 'C01', 'Shelf D - Row 1', 'Available', 'New'),
('B08', 'C01', 'Shelf D - Row 2', 'Available', 'Good'),
('B09', 'C01', 'Shelf E - Row 1', 'Available', 'Good'),   -- never lent, so B09 was never fully on loan
('B09', 'C02', 'Shelf E - Row 1', 'Borrowed',  'Good'),   -- out on loan L09
('B10', 'C01', 'Shelf E - Row 2', 'Available', 'Fair: cover slightly worn'),
('B11', 'C01', 'Shelf F - Row 1', 'Available', 'Good'),
('B12', 'C01', 'Shelf F - Row 2', 'Borrowed',  'Good'),   -- out on loan L11
('B13', 'C01', 'Shelf F - Row 3', 'Borrowed',  'Good'),   -- out on loan L15
('B14', 'C01', 'Shelf G - Row 1', 'Available', 'New'),    -- never lent
('B15', 'C01', 'Shelf G - Row 2', 'Available', 'New');    -- never lent
 
-- Reservation (15 rows)
-- A member reserves a title only when no copy of it is on the shelf (each
-- copy is borrowed, kept for another member, damaged or lost). When a copy
-- comes back, the member who reserved first gets it: the queue for a title
-- follows Reservation_Date.
--   Pending    still waiting for a copy
--   Confirmed  a returned copy is kept at the desk for the member
--   Completed  the member has collected the book
--   Cancelled  the member cancelled, or never collected the copy
 
INSERT INTO Reservation (Reservation_ID, Member_ID, Book_ID, Reservation_Date, Status) VALUES
-- January to September: older reservations
('RES01', 'M11', 'B11', '2026-01-20', 'Cancelled'),  -- The Interpretation of Dreams: only copy out on loan L01
('RES02', 'M04', 'B04', '2026-03-20', 'Cancelled'),  -- Refactoring: C01 out on loan L04, C02 lost
('RES03', 'M07', 'B05', '2026-04-20', 'Cancelled'),  -- The Art of Computer Programming: only copy out on loan L05
('RES04', 'M10', 'B07', '2026-06-01', 'Cancelled'),  -- The Theory of Relativity: only copy out on loan L07
('RES05', 'M03', 'B08', '2026-07-01', 'Cancelled'),  -- The Feynman Lectures on Physics: only copy out on loan L08
('RES06', 'M13', 'B10', '2026-07-20', 'Cancelled'),  -- On the Origin of Species: only copy out on loan L10
('RES07', 'M02', 'B03', '2026-09-02', 'Confirmed'),  -- Clean Code: both copies were out; C01 came back on 2026-09-04 and is kept at the desk for M02
('RES08', 'M12', 'B02', '2026-09-03', 'Cancelled'),  -- Algorithms Unlocked: both copies were out; C01 came back on 2026-09-06, but M12 never picked it up
-- October: members still waiting
('RES09', 'M05', 'B06', '2026-10-05', 'Pending'),    -- Mathematical Methods: C01 damaged, C02 out on loan L06; 1st in the queue
('RES10', 'M06', 'B12', '2026-10-06', 'Pending'),    -- Hamlet: only copy out on loan L11; 1st in the queue
('RES11', 'M03', 'B03', '2026-10-09', 'Pending'),    -- Clean Code: C01 kept for RES07, C02 out on loan L03; next after RES07
('RES12', 'M08', 'B13', '2026-10-12', 'Pending'),    -- Pride and Prejudice: only copy out on loan L15; 1st in the queue
('RES13', 'M12', 'B12', '2026-10-12', 'Pending'),    -- Hamlet: 2nd in the queue, after RES10
('RES14', 'M04', 'B06', '2026-10-14', 'Pending'),    -- Mathematical Methods: 2nd in the queue, after RES09
('RES15', 'M11', 'B13', '2026-10-18', 'Pending');    -- Pride and Prejudice: 2nd in the queue, after RES12
 
-- Loan_Detail (18 rows)
-- The fine of a line is not stored: the view Loan_Detail_Fine computes it
-- (5,000 VND per day late). Payment_Status says whether that fine is
-- Unpaid, Paid or Waived, and is 'None' for a copy returned on time.
-- Copies still out (Return_Date NULL) were already overdue when this data was
-- entered, so they are marked 'Unpaid'; L15 was not due yet, so it is 'None'.
 
INSERT INTO Loan_Detail (Loan_ID, Detail_ID, Book_ID, Copy_ID, Return_Date, Renewal_Count, Payment_Status) VALUES
('L01', 'D01', 'B01', 'C01', '2026-01-24', 0, 'None'),
('L01', 'D02', 'B11', 'C01', '2026-01-24', 0, 'None'),
('L02', 'D01', 'B01', 'C02', '2026-02-23', 0, 'None'),
('L02', 'D02', 'B02', 'C01', '2026-03-04', 0, 'Paid'),     -- 7 days late: 35,000 VND
('L03', 'D01', 'B02', 'C02', NULL,         0, 'Unpaid'),
('L03', 'D02', 'B03', 'C02', NULL,         0, 'Unpaid'),
('L04', 'D01', 'B04', 'C01', '2026-04-02', 0, 'Unpaid'),   -- 8 days late: 40,000 VND
('L05', 'D01', 'B05', 'C01', '2026-04-30', 0, 'Unpaid'),   -- 8 days late: 40,000 VND
('L06', 'D01', 'B06', 'C02', NULL,         0, 'Unpaid'),
('L07', 'D01', 'B07', 'C01', '2026-06-03', 0, 'None'),
('L08', 'D01', 'B08', 'C01', '2026-07-13', 0, 'Unpaid'),   -- 10 days late: 50,000 VND
('L09', 'D01', 'B09', 'C02', NULL,         0, 'Unpaid'),
('L10', 'D01', 'B10', 'C01', '2026-07-30', 0, 'Paid'),     -- 5 days late: 25,000 VND
('L11', 'D01', 'B12', 'C01', NULL,         0, 'Unpaid'),
('L12', 'D01', 'B01', 'C01', '2026-09-10', 1, 'None'),     -- renewed once, returned on the due date
('L13', 'D01', 'B02', 'C01', '2026-09-06', 0, 'Waived'),   -- 5 days late: 25,000 VND, waived
('L14', 'D01', 'B03', 'C01', '2026-09-04', 0, 'None'),
('L15', 'D01', 'B13', 'C01', NULL,         0, 'None');
 
 
 
DROP TRIGGER IF EXISTS trigger_loantransaction_before_insertMember;
DROP TRIGGER IF EXISTS trg_before_loan_detail_insert_check_copy;
DROP TRIGGER IF EXISTS trg_before_loan_detail_update_check;
DROP TRIGGER IF EXISTS trg_staff_before_insert_hierarchy;
DROP TRIGGER IF EXISTS trg_staff_before_update_hierarchy;

DELIMITER $$
 
-- Trigger 1  Enforces BR03 on Loan_Transaction
CREATE TRIGGER trigger_loantransaction_before_insertMember
BEFORE INSERT ON Loan_Transaction
FOR EACH ROW
BEGIN
    DECLARE v_status       VARCHAR(20); -- account status
    DECLARE v_expiry       DATE; -- this is for membership_expiry_date
    DECLARE v_limit        INT; -- borrow limit
    DECLARE v_loan_period  INT; -- loan _ period
    DECLARE v_active_loans INT;
 
    SELECT m.Account_Status, m.Membership_Expiry_Date,
           mc.Borrowing_Limit, mc.Loan_Period
    INTO v_status, v_expiry, v_limit, v_loan_period
    FROM Member m
    INNER JOIN Member_Category mc
        ON m.Member_Type_ID = mc.Member_Type_ID
    WHERE m.Member_ID = NEW.Member_ID;
 
    IF v_status IS NOT NULL THEN
        IF v_status <> 'Active' THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'BR03 Violation: Member account is not Active and cannot borrow books.';
        END IF;
 
        IF v_expiry < NEW.Borrow_Date THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'BR03 Violation: Membership card has expired prior to the borrow date.';
        END IF;
 
        IF DATEDIFF(NEW.Due_Date, NEW.Borrow_Date) > v_loan_period THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'BR03 Violation: Loan duration exceeds the allowed period for this membership category.';
        END IF;
 
        SELECT COUNT(*) -- count books not return 
        INTO v_active_loans -- số cuốn sách đang giữ chưa trả
        FROM Loan_Transaction lt
        INNER JOIN Loan_Detail ld
            ON lt.Loan_ID = ld.Loan_ID
        WHERE lt.Member_ID = NEW.Member_ID
          AND ld.Return_Date IS NULL; -- number of book that is not return 
 
        IF (v_active_loans + 1) > v_limit THEN -- chặn việc mượn quá sách
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'BR03 Violation: Borrowing limit exceeded for this membership category.';
        END IF;
    END IF;
END$$
 
-- Trigger 2  Enforces BR02 on Loan_Detail (new loan line)
--   BR05: a line entered as already returned after the due date must
--        carry a fine, and a line returned on time must not.
--   BR03: the borrowing limit is checked on the copies the member really
--        has out (Trigger 1 runs once, before any copy is added).
CREATE TRIGGER trg_before_loan_detail_insert_check_copy
BEFORE INSERT ON Loan_Detail
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(50)  DEFAULT NULL;
    DECLARE v_msg    VARCHAR(128) DEFAULT NULL;
    DECLARE v_member VARCHAR(20)  DEFAULT NULL;
    DECLARE v_due    DATE         DEFAULT NULL;
    DECLARE v_limit  INT          DEFAULT NULL;
    DECLARE v_open   INT          DEFAULT 0;
    DECLARE v_borrow DATE         DEFAULT NULL;
 
    -- The loan this line belongs to: who borrows, the dates, the limit
    SELECT lt.Member_ID, lt.Borrow_Date, lt.Due_Date, mc.Borrowing_Limit
    INTO v_member, v_borrow, v_due, v_limit
    FROM Loan_Transaction lt
    INNER JOIN Member m
        ON lt.Member_ID = m.Member_ID
    INNER JOIN Member_Category mc
        ON m.Member_Type_ID = mc.Member_Type_ID
    WHERE lt.Loan_ID = NEW.Loan_ID;
 
    -- A copy cannot come back before it went out. A CHECK cannot see
    -- Borrow_Date, which lives in Loan_Transaction, so the trigger does it.
    IF NEW.Return_Date IS NOT NULL AND NEW.Return_Date < v_borrow THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Date Violation: Return_Date cannot be earlier than the Borrow_Date of the loan.';
    END IF;
 
    -- BR05: returned after the due date, so a fine must be recorded
    -- (Unpaid, Paid or Waived); returned on time, so no fine (None).
    -- The amount itself is computed by the view Loan_Detail_Fine.
    IF NEW.Return_Date IS NOT NULL AND NEW.Return_Date > v_due AND NEW.Payment_Status = 'None' THEN -- trả trễ mà không ghi nhận phạt
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'BR05 Violation: A copy returned after its due date must carry a fine (Unpaid, Paid or Waived).';
    END IF;
 
    IF NEW.Return_Date IS NOT NULL AND NEW.Return_Date <= v_due AND NEW.Payment_Status <> 'None' THEN
        SIGNAL SQLSTATE '45000'     
            SET MESSAGE_TEXT = 'BR05 Violation: A copy returned on time has no fine, so its Payment_Status must be None.';
    END IF;
 
    IF NEW.Return_Date IS NULL THEN
        SELECT Status INTO v_status
        FROM Book_Copy
        WHERE Book_ID = NEW.Book_ID AND Copy_ID = NEW.Copy_ID;
 
        IF v_status IS NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'BR02 Violation: Cannot lend because this book copy does not exist.';
        ELSEIF v_status NOT IN ('Available', 'Reserved') THEN
            SET v_msg = CONCAT('BR02 Violation: Cannot lend because this copy is not available (status: ', v_status, ').');
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = v_msg;
        END IF;
 
        -- BR02: one physical copy is on at most one open loan line. Status
        -- is set by hand, so the trigger also looks at the open lines.
        IF EXISTS (SELECT 1
                   FROM Loan_Detail
                   WHERE Book_ID = NEW.Book_ID
                     AND Copy_ID = NEW.Copy_ID
                     AND Return_Date IS NULL) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'BR02 Violation: This copy is already out on another loan that has not been returned.';
        END IF;
 
        -- BR03: copies this member already has out, plus this one
        SELECT COUNT(*)
        INTO v_open
        FROM Loan_Detail ld
        INNER JOIN Loan_Transaction lt
            ON ld.Loan_ID = lt.Loan_ID
        WHERE lt.Member_ID = v_member
          AND ld.Return_Date IS NULL;
 
        IF v_open + 1 > v_limit THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'BR03 Violation: Borrowing limit exceeded for this membership category.';
        END IF;
    END IF;
END$$
 
-- Trigger 3  BEFORE UPDATE on Loan_Detail.
--   BR05: a copy returned after its due date carries a fine, and a copy
--         returned on time carries none;
--   BR03: a line that becomes open again (Return_Date set back to NULL) or is
--         moved to another loan must still fit the member's borrowing limit;
--   BR02: a line that becomes open, or points to another copy, must not put
--         one copy on two open loans;
--   a copy cannot be returned before the loan's Borrow_Date.
 
CREATE TRIGGER trg_before_loan_detail_update_check
BEFORE UPDATE ON Loan_Detail
FOR EACH ROW
BEGIN
    DECLARE v_member VARCHAR(20) DEFAULT NULL;
    DECLARE v_borrow DATE        DEFAULT NULL;
    DECLARE v_due    DATE        DEFAULT NULL;
    DECLARE v_limit  INT         DEFAULT NULL;
    DECLARE v_open   INT         DEFAULT 0;
 
    SELECT lt.Member_ID, lt.Borrow_Date, lt.Due_Date, mc.Borrowing_Limit
    INTO v_member, v_borrow, v_due, v_limit
    FROM Loan_Transaction lt
    INNER JOIN Member m
        ON lt.Member_ID = m.Member_ID
    INNER JOIN Member_Category mc
        ON m.Member_Type_ID = mc.Member_Type_ID
    WHERE lt.Loan_ID = NEW.Loan_ID;
 
    IF NEW.Return_Date IS NOT NULL AND NEW.Return_Date < v_borrow THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Date Violation: Return_Date cannot be earlier than the Borrow_Date of the loan.';
    END IF;
 
    IF NEW.Return_Date IS NULL
       AND (OLD.Return_Date IS NOT NULL
            OR NEW.Book_ID <> OLD.Book_ID
            OR NEW.Copy_ID <> OLD.Copy_ID)
       AND EXISTS (SELECT 1
                   FROM Loan_Detail ld
                   WHERE ld.Book_ID = NEW.Book_ID
                     AND ld.Copy_ID = NEW.Copy_ID
                     AND ld.Return_Date IS NULL
                     AND NOT (ld.Loan_ID = OLD.Loan_ID AND ld.Detail_ID = OLD.Detail_ID)) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'BR02 Violation: This copy is already out on another loan that has not been returned.';
    END IF;
 
    IF NEW.Return_Date IS NOT NULL AND NEW.Return_Date > v_due AND NEW.Payment_Status = 'None' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'BR05 Violation: A copy returned after its due date must carry a fine (Unpaid, Paid or Waived).';
    END IF;
 
    IF NEW.Return_Date IS NOT NULL AND NEW.Return_Date <= v_due AND NEW.Payment_Status <> 'None' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'BR05 Violation: A copy returned on time has no fine, so its Payment_Status must be None.';
    END IF;
 
    IF NEW.Return_Date IS NULL
       AND (OLD.Return_Date IS NOT NULL OR NEW.Loan_ID <> OLD.Loan_ID) THEN
        SELECT COUNT(*)
        INTO v_open
        FROM Loan_Detail ld
        INNER JOIN Loan_Transaction lt
            ON ld.Loan_ID = lt.Loan_ID
        WHERE lt.Member_ID = v_member
          AND ld.Return_Date IS NULL
          AND NOT (ld.Loan_ID = OLD.Loan_ID AND ld.Detail_ID = OLD.Detail_ID);
 
        IF v_open + 1 > v_limit THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'BR03 Violation: Borrowing limit exceeded for this membership category.';
        END IF;
    END IF;
END$$
 
-- Triggers 4 and 5  Enforce BR04 on Staff: nobody supervises themself
--   (the FK alone only checks that the supervisor exists).
CREATE TRIGGER trg_staff_before_insert_hierarchy
BEFORE INSERT ON Staff
FOR EACH ROW
BEGIN
    IF NEW.Supervisor_ID = NEW.Staff_ID THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'BR04 Violation: A staff member cannot be their own supervisor.';
    END IF;
END$$
 
CREATE TRIGGER trg_staff_before_update_hierarchy
BEFORE UPDATE ON Staff
FOR EACH ROW
BEGIN
    IF NEW.Supervisor_ID = NEW.Staff_ID THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'BR04 Violation: A staff member cannot be their own supervisor.';
    END IF;
END$$

DELIMITER ;
 
 
 
-- =====================================================================
-- UPDATE STATEMENTS USED BY THE APPLICATION
-- Requirement 2.3: "at least one INSERT, one UPDATE and one DELETE for
-- each main table".
--
-- Main tables (our reading of the requirement): the 11 tables that map an
-- entity set of the ER diagram. Each one is edited through its own screen
-- in the Java application.
--   Catalogue    Category, Publisher, Author, Book, Book_Copy
--   Members      Member_Category, Member, Staff
--   Circulation  Reservation, Loan_Transaction, Loan_Detail


-- ---------------------------------------------------------------------
-- Main table 1: Category                              (Category screen)
-- ---------------------------------------------------------------------
-- INSERT: add a new subject
INSERT INTO Category (Category_ID, Category_Name, Description)
VALUES ('CAT16', 'Data Science', 'Big data analytics, data mining, and visualization.');

-- UPDATE: edit the description of the subject
UPDATE Category
SET Description = 'Big data analytics, statistical modeling, and visualization.'
WHERE Category_ID = 'CAT16';

-- DELETE: remove a subject that no title uses
-- (fk_book_category is RESTRICT: a subject still in use cannot be deleted)
DELETE FROM Category
WHERE Category_ID = 'CAT16';


-- ---------------------------------------------------------------------
-- Main table 2: Publisher                            (Publisher screen)
-- ---------------------------------------------------------------------
-- INSERT: add a publisher
INSERT INTO Publisher (Publisher_ID, Publisher_Name, Address, Contact_Email)
VALUES ('PUB16', 'Addison-Wesley', 'Boston, MA, USA', 'contact@aw.com');

-- UPDATE: correct the address
UPDATE Publisher
SET Address = 'Boston, Massachusetts, USA'
WHERE Publisher_ID = 'PUB16';

-- DELETE: remove a publisher that has no titles
-- (fk_book_publisher is RESTRICT)
DELETE FROM Publisher
WHERE Publisher_ID = 'PUB16';


-- ---------------------------------------------------------------------
-- Main table 3: Author                                  (Author screen)
-- ---------------------------------------------------------------------
-- INSERT: add an author
INSERT INTO Author (Author_ID, Author_Name, Biography)
VALUES ('AUTH19', 'Andrew S. Tanenbaum', 'Professor Emeritus of Computer Science at Vrije Universiteit Amsterdam.');

-- UPDATE: edit the biography
UPDATE Author
SET Biography = 'Author of Modern Operating Systems and Computer Networks.'
WHERE Author_ID = 'AUTH19';

-- DELETE: remove an author who is linked to no title
-- (fk_ba_author is RESTRICT)
DELETE FROM Author
WHERE Author_ID = 'AUTH19';


-- ---------------------------------------------------------------------
-- Main table 4: Book, with its authors in Book_Author       (Book screen)
-- ---------------------------------------------------------------------
-- INSERT: catalogue a new title, then link its authors
-- (Leiserson is entered at position 3 by mistake)
INSERT INTO Book (Book_ID, Category_ID, Publisher_ID, ISBN, Title, Publication_Year)
VALUES ('B16', 'CAT01', 'PUB01', '978-0262046305', 'Introduction to Algorithms, 4th Edition', 2022);

INSERT INTO Book_Author (Book_ID, Author_ID, Author_Order)
VALUES ('B16', 'AUTH01', 1),
       ('B16', 'AUTH16', 3);

-- UPDATE: correct the title, then correct Leiserson's position to 2
UPDATE Book
SET Title = 'Introduction to Algorithms, Fourth Edition'
WHERE Book_ID = 'B16';

UPDATE Book_Author
SET Author_Order = 2
WHERE Book_ID = 'B16' AND Author_ID = 'AUTH16';

-- DELETE: unlink one author, then remove the title. The title has no
-- copies, and its remaining author link goes with it (fk_ba_book is CASCADE).
DELETE FROM Book_Author
WHERE Book_ID = 'B16' AND Author_ID = 'AUTH16';

DELETE FROM Book
WHERE Book_ID = 'B16';


-- ---------------------------------------------------------------------
-- Main table 5: Book_Copy                                (Copy screen)
-- ---------------------------------------------------------------------
-- INSERT: add a second copy of an existing title (B15 '1984')
INSERT INTO Book_Copy (Book_ID, Copy_ID, Shelf_Location, Status, Condition_Notes)
VALUES ('B15', 'C02', 'Shelf G - Row 2', 'Available', 'New');

-- UPDATE: record damage found during a shelf check
UPDATE Book_Copy
SET Status = 'Damaged', Condition_Notes = 'Damaged: water damage on the cover'
WHERE Book_ID = 'B15' AND Copy_ID = 'C02';

-- DELETE: write the copy off; allowed because it was never lent
-- (FK_loandetail_borrowed_BookCopy is RESTRICT)
DELETE FROM Book_Copy
WHERE Book_ID = 'B15' AND Copy_ID = 'C02';


-- ---------------------------------------------------------------------
-- Main table 6: Member_Category               (Membership category screen)
-- ---------------------------------------------------------------------
-- INSERT: add a membership category
INSERT INTO Member_Category (Member_Type_ID, Type_Name, Borrowing_Limit, Loan_Period)
VALUES ('MC16', 'Short-Term Research Visitor', 4, 14);

-- UPDATE: change its borrowing limit and loan period
UPDATE Member_Category
SET Borrowing_Limit = 5, Loan_Period = 17
WHERE Member_Type_ID = 'MC16';

-- DELETE: remove a category that no member belongs to
-- (FK_Memberbelongto_category is RESTRICT)
DELETE FROM Member_Category
WHERE Member_Type_ID = 'MC16';


-- ---------------------------------------------------------------------
-- Main table 7: Member, with its phones in Member_Phone   (Member screen)
-- ---------------------------------------------------------------------
-- INSERT: register a new member and record a phone number
INSERT INTO Member (Member_ID, Member_Type_ID, Full_Name, Email, Identity_Card, Membership_Expiry_Date, Account_Status)
VALUES ('M16', 'MC01', 'Nguyen Minh Tri', 'nmtri@hcmiu.edu.vn', '079205001016', '2027-08-31', 'Active');

INSERT INTO Member_Phone (Member_ID, Phone)
VALUES ('M16', '0909998816');

-- UPDATE: renew the membership card for one more year, then change the
-- phone number
UPDATE Member
SET Membership_Expiry_Date = '2028-08-31'
WHERE Member_ID = 'M16';

UPDATE Member_Phone
SET Phone = '0909998877'
WHERE Member_ID = 'M16' AND Phone = '0909998816';

-- DELETE: remove the phone number, then the member; allowed because the
-- member has no loans (FK_loantransactionMakeMember is RESTRICT)
DELETE FROM Member_Phone
WHERE Member_ID = 'M16' AND Phone = '0909998877';

DELETE FROM Member
WHERE Member_ID = 'M16';


-- ---------------------------------------------------------------------
-- Main table 8: Staff                                    (Staff screen)
-- ---------------------------------------------------------------------
-- INSERT: add a staff member under the Head of Circulation (S03)
INSERT INTO Staff (Staff_ID, Supervisor_ID, Full_Name, Position, Email)
VALUES ('S16', 'S03', 'Pham Hoang Nam', 'Assistant Circulation Librarian', 'phnam@hcmiu.edu.vn');

-- UPDATE: transfer to the reference team under S02
-- (Trigger 5 checks that S16 is not made their own supervisor)
UPDATE Staff
SET Position = 'Reference Librarian', Supervisor_ID = 'S02'
WHERE Staff_ID = 'S16';

-- DELETE: remove a staff member who handled no loans
-- (FK_loanhandlesStaffID is RESTRICT)
DELETE FROM Staff
WHERE Staff_ID = 'S16';


-- ---------------------------------------------------------------------
-- Main table 9: Reservation                        (Reservation screen)
-- ---------------------------------------------------------------------
-- INSERT: M02 reserves B12, whose only copy is out on loan L11
-- (the Java application checks that the title is fully on loan)
INSERT INTO Reservation (Reservation_ID, Member_ID, Book_ID, Reservation_Date, Status)
VALUES ('RES16', 'M02', 'B12', '2026-10-23', 'Pending');

-- UPDATE: the member cancels the reservation
UPDATE Reservation
SET Status = 'Cancelled'
WHERE Reservation_ID = 'RES16';

-- DELETE: remove the cancelled reservation
DELETE FROM Reservation
WHERE Reservation_ID = 'RES16';


-- ---------------------------------------------------------------------
-- Main tables 10 and 11: Loan_Transaction (header) and Loan_Detail (lines)
--                                  (Checkout and return screen, master-detail)
-- Changing Book_Copy.Status together with the loan is shown in
-- Transaction 1 below.
-- ---------------------------------------------------------------------
-- INSERT: M04 borrows copy B14-C01 for 10 days
-- (Trigger 1 checks the header, Trigger 2 checks the line)
INSERT INTO Loan_Transaction (Loan_ID, Member_ID, Staff_ID, Borrow_Date, Due_Date)
VALUES ('L16', 'M04', 'S05', '2026-10-20', '2026-10-30');

INSERT INTO Loan_Detail (Loan_ID, Detail_ID, Book_ID, Copy_ID, Return_Date, Renewal_Count, Payment_Status)
VALUES ('L16', 'D01', 'B14', 'C01', NULL, 0, 'None');

-- UPDATE: renew the copy once and move the due date to 2026-11-09
-- (20 days in total, within two loan periods of category MC01)
UPDATE Loan_Detail
SET Renewal_Count = 1
WHERE Loan_ID = 'L16' AND Detail_ID = 'D01';

UPDATE Loan_Transaction
SET Due_Date = '2026-11-09'
WHERE Loan_ID = 'L16';

-- UPDATE: record the return on 2026-11-05, before the due date, so no
-- fine is needed (Trigger 3 checks the return date and the fine)
UPDATE Loan_Detail
SET Return_Date = '2026-11-05'
WHERE Loan_ID = 'L16' AND Detail_ID = 'D01';

-- DELETE: remove the demo loan, the line first and then the header.
-- In practice a loan is deleted only when it was entered by mistake;
-- returned loans are kept as history.
DELETE FROM Loan_Detail
WHERE Loan_ID = 'L16' AND Detail_ID = 'D01';

DELETE FROM Loan_Transaction
WHERE Loan_ID = 'L16';


-- =====================================================================
-- TRANSACTIONS
-- Requirement 2.3: "at least one operation that changes two tables
-- together and therefore runs inside a transaction with COMMIT and
-- ROLLBACK". Either every change of the operation is kept (COMMIT) or
-- none is (ROLLBACK).
-- =====================================================================

--  TRANSACTION 1 (COMMIT): Atomic Book Checkout across 3 tables
START TRANSACTION;
 
INSERT INTO Loan_Transaction (Loan_ID, Member_ID, Staff_ID, Borrow_Date, Due_Date)
VALUES ('L17', 'M04', 'S05', '2026-10-20', '2026-10-30');
 
INSERT INTO Loan_Detail (Loan_ID, Detail_ID, Book_ID, Copy_ID, Return_Date, Renewal_Count, Payment_Status)
VALUES ('L17', 'D01', 'B14', 'C01', NULL, 0, 'None');
 
UPDATE Book_Copy
SET Status = 'Borrowed'
WHERE Book_ID = 'B14' AND Copy_ID = 'C01';
 
COMMIT;
 
--  TRANSACTION 2 (ROLLBACK): Cancelled Return & Fine Payment on L03
START TRANSACTION;
 
-- 1. Record the return 
UPDATE Loan_Detail
SET Return_Date = '2026-10-23'
WHERE Loan_ID = 'L03' AND Detail_ID = 'D01' AND Return_Date IS NULL;
 
-- 2. Pay the fine
UPDATE Loan_Detail
SET Payment_Status = 'Paid'
WHERE Loan_ID = 'L03' AND Detail_ID = 'D01';
 
-- 3. Release the physical copy
UPDATE Book_Copy
SET Status = 'Available'
WHERE Book_ID = 'B02' AND Copy_ID = 'C02';
 
-- 4. Payment gateway reports FAILURE -> undo changes to both tables (Atomicity)
ROLLBACK;
 
-- Restore baseline state for ('B14', 'C01') and L17 so sample data stays clean
START TRANSACTION;
DELETE FROM Loan_Transaction WHERE Loan_ID = 'L17';
UPDATE Book_Copy
SET Status = 'Available'
WHERE Book_ID = 'B14' AND Copy_ID = 'C01';
COMMIT;
