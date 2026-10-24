
-- PROJECT:     Topic 22 - Library Management System
-- DBMS:        MySQL 8.4 LTS | Tool: MySQL Workbench



SET NAMES utf8mb4;
SET SESSION sql_mode = 'STRICT_ALL_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

DROP DATABASE IF EXISTS library_management_db;
CREATE DATABASE library_management_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE library_management_db;


-- BR01: A physical book copy (Book_Copy) cannot exist independently without
--       being associated with a parent book title (Book).
-- BR02: Book reservations (Reservation) are placed on a specific Book (title),
--       whereas active loans (Loan_Detail) are tracked by physical book copies
--       (Book_Copy).
-- BR03: Member borrowing privileges (limits and loan durations) are strictly
--       governed by their membership category (Member_Category).
-- BR04: Staff members operate under an organizational hierarchy where a staff
--       member may report to a designated supervisor (Staff self-reference).
-- BR05: Overdue books incur fines which are tracked for each specific borrowed
--       copy in the Loan_Detail table, along with their payment statuses.

--         Where each rule is enforced
--   BR01  Book_Copy.Book_ID NOT NULL, PK (Book_ID, Copy_ID),
--         FK fk_copy_book ON DELETE CASCADE (copies go with their title)
--   BR02  Reservation: FK fk_res_book (title level, no copy column);
--         Loan_Detail: composite FK FK_loandetail_borrowed_BookCopy (copy level)
--   BR03  Member.Member_Type_ID NOT NULL + FK; CHECK check_MemberCategoryLimit;
--         Trigger 1 (loan period and limit at checkout), Trigger 2 (changed
--         due date or member), Trigger 3 (limit on the copies really out),
--         Trigger 4 (loan line re-opened or moved)
--   BR04  FK FK_staffSupervisor (NULL = top of the hierarchy);
--         Triggers 5 and 6 (nobody supervises themself, no cycle)
--   BR05  Fine_Amount + Payment_Status in every Loan_Detail row; CHECK
--         check_loandetail_fine_amount, check_loandetail_paymentstatus;
--         Triggers 3 and 4 (a copy returned late carries a fine)




-- table 1 
-- Enforces BR03: Defines borrowing limits and loan durations per membership tier
-- ----------------------------------------------------------------------------
CREATE TABLE Member_Category (
    Member_Type_ID  VARCHAR(20) NOT NULL,
    Type_Name       VARCHAR(50) NOT NULL,
    Borrowing_Limit INT         NOT NULL DEFAULT 3,
    Loan_Period     INT         NOT NULL DEFAULT 14,
    CONSTRAINT PK_Member_Category
        PRIMARY KEY (Member_Type_ID),
    CONSTRAINT unique_Member_Category_TypeName
        UNIQUE (Type_Name),
    CONSTRAINT check_MemberCategoryLimit
        CHECK (Borrowing_Limit BETWEEN 1 AND 20 AND Loan_Period BETWEEN 1 AND 90) -- each Member category can borrow difference limit and difference loan
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
    Description   TEXT         NULL,
    CONSTRAINT pk_category
        PRIMARY KEY (Category_ID),
    CONSTRAINT uq_category_name
        UNIQUE (Category_Name),
    -- [S1] Every table carries a CHECK (section 2.2): a category needs a name.
    CONSTRAINT chk_category_name_not_blank
        CHECK (CHAR_LENGTH(TRIM(Category_Name)) > 0)
) ENGINE=InnoDB;


-- table 5  Publisher
-- Book publishing house master table

CREATE TABLE Publisher (
    Publisher_ID   VARCHAR(20)  NOT NULL,
    Publisher_Name VARCHAR(150) NOT NULL,
    Address        VARCHAR(255) NULL DEFAULT NULL,
    Contact_Email  VARCHAR(100) NULL DEFAULT NULL,
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
    -- [S2] An author needs a name. Author_Name is not UNIQUE on purpose:
    -- two different authors may share a name.
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

CREATE TABLE Loan_Transaction (
    Loan_ID               VARCHAR(20) NOT NULL,
    Member_ID             VARCHAR(20) NOT NULL,
    Staff_ID              VARCHAR(20) NOT NULL,
    Borrow_Date           DATE        NOT NULL DEFAULT (CURRENT_DATE),
    Due_Date              DATE        NOT NULL,
    Total_Copies_Borrowed INT         NOT NULL DEFAULT 1,
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
        CHECK (Due_Date >= Borrow_Date),
    CONSTRAINT check_loantransaction_totalcopies
        CHECK (Total_Copies_Borrowed BETWEEN 1 AND 20)
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
-- Enforces BR02: Reservations reference Book_ID (title level), whereas

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

CREATE TABLE Loan_Detail (
    Loan_ID        VARCHAR(20)    NOT NULL,
    Detail_ID      VARCHAR(20)    NOT NULL,
    Book_ID        VARCHAR(20)    NOT NULL,
    Copy_ID        VARCHAR(20)    NOT NULL,
    Return_Date    DATE           NULL DEFAULT NULL,
    Renewal_Count  INT            NOT NULL DEFAULT 0,
    Payment_Status VARCHAR(20)    NOT NULL DEFAULT 'None',
    Fine_Amount    DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
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
    CONSTRAINT check_loandetail_fine_amount
        CHECK (Fine_Amount >= 0.00),
    CONSTRAINT check_loandetail_paymentstatus
        CHECK (
            Payment_Status IN ('None', 'Unpaid', 'Paid', 'Waived')
            AND (
                (Fine_Amount = 0.00 AND Payment_Status = 'None')
                OR (Fine_Amount > 0.00 AND Payment_Status IN ('Unpaid', 'Paid', 'Waived'))
            )
        )
) ENGINE=InnoDB;


-- [S5] Each index and the Topic 22 query it helps (copy this into the report)
-- Circulation and fines
CREATE INDEX index_loanTransaction_member_due ON Loan_Transaction (Member_ID, Due_Date);    -- Q2 loans of one member overdue today
CREATE INDEX idx_loan_detail_return_date      ON Loan_Detail (Return_Date);                 -- Q2 copies not returned (Return_Date IS NULL)
CREATE INDEX idx_loantransaction_borrow_date  ON Loan_Transaction (Borrow_Date);            -- Q3 ten most borrowed titles this year (year as a date range)
CREATE INDEX idx_loan_detail_payment_fine     ON Loan_Detail (Payment_Status, Fine_Amount); -- Q5 fines outstanding per member category
-- Catalogue and authors
CREATE INDEX idx_book_title                   ON Book (Title);                              -- Q1 find a title by name (prefix search)
CREATE INDEX idx_book_copy_status             ON Book_Copy (Book_ID, Status);               -- Q1 copies of a title currently available
CREATE INDEX idx_author_name                  ON Author (Author_Name);                      -- Q4 titles by a given author



--  Member_Category (15 rows)
INSERT INTO Member_Category (Member_Type_ID, Type_Name, Borrowing_Limit, Loan_Period) VALUES
('MC01', 'Undergraduate Student', 5, 14),
('MC02', 'Postgraduate Student', 8, 21),
('MC03', 'Doctoral Researcher', 12, 30),
('MC04', 'Full-Time Lecturer', 15, 45),
('MC05', 'Visiting Scholar', 10, 30),
('MC06', 'Library Staff Member', 10, 30),
('MC07', 'Administrative Staff', 6, 14),
('MC08', 'Alumni Standard', 3, 14),
('MC09', 'Alumni Gold', 6, 21),
('MC10', 'Exchange Student', 4, 14),
('MC11', 'External Reader', 2, 7),
('MC12', 'High School Gifted Student', 3, 14),
('MC13', 'Corporate Partner', 8, 21),
('MC14', 'Retired Faculty', 10, 45),
('MC15', 'Honorary Fellow', 20, 60);

--  Member (15 rows)
INSERT INTO Member (Member_ID, Member_Type_ID, Full_Name, Email, Identity_Card, Membership_Expiry_Date, Account_Status) VALUES
('M01', 'MC01', 'Tran Duc Thinh', 'tdthinh@hcmiu.edu.vn', '079205001001', '2027-08-31', 'Active'),
('M02', 'MC02', 'Phung Dinh Duc', 'pdduc@hcmiu.edu.vn', '079205001002', '2027-08-31', 'Active'),
('M03', 'MC03', 'Nguyen Ngoc Phuong Nam', 'nnpnam@hcmiu.edu.vn', '079205001003', '2027-12-31', 'Active'),
('M04', 'MC01', 'Nguyen Duc Thinh', 'ndthinh@hcmiu.edu.vn', '079205001004', '2027-08-31', 'Active'),
('M05', 'MC04', 'Tran Trung Kien', 'ttkien@hcmiu.edu.vn', '079205001005', '2028-06-30', 'Active'),
('M06', 'MC05', 'Nguyen Ngoc Truong Son', 'nntson@hcmiu.edu.vn', '079205001006', '2027-05-15', 'Active'),
('M07', 'MC01', 'Mai Dang Quang Huy', 'maidangquanghuy@hcmiu.edu.vn', '079205001007', '2027-08-31', 'Active'),
('M08', 'MC02', 'Phan Gia Huy', 'pghuy@hcmiu.edu.vn', '079205001008', '2027-09-30', 'Active'),
('M09', 'MC08', 'Dang Hoang Anh', 'dhanh@hcmiu.edu.vn', '079205001009', '2027-03-31', 'Suspended'),
('M10', 'MC04', 'Roan Khoi Nguyen', 'rknguyen@hcmiu.edu.vn', '079205001010', '2028-12-31', 'Active'),
('M11', 'MC07', 'Bui Nguyen Duy Loi', 'bndloi@hcmiu.edu.vn', '079205001011', '2027-10-31', 'Active'),
('M12', 'MC10', 'Mai Bui Quoc Viet', 'mbqviet@hcmiu.edu.vn', '079205001012', '2027-01-31', 'Active'),
('M13', 'MC03', 'Le Hoang Minh', 'lhminh@hcmiu.edu.vn', '079205001013', '2027-11-30', 'Active'),
('M14', 'MC11', 'Vo Thi Bich Ngoc', 'vtbngoc@gmail.com', '079205001014', '2026-04-30', 'Expired'),
('M15', 'MC09', 'Hoang Gia Bao', 'hgbao@alumni.hcmiu.edu.vn', '079205001015', '2027-07-31', 'Locked');

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
('PUB03', 'O''Reilly Media', 'Sebastopol, CA, USA', 'support@oreilly.com'),  -- [D1] real name; '' is one apostrophe
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

INSERT INTO Loan_Transaction (Loan_ID, Member_ID, Staff_ID, Borrow_Date, Due_Date, Total_Copies_Borrowed) VALUES
('L01', 'M01', 'S05', '2026-01-15', '2026-01-29', 2),
('L02', 'M02', 'S05', '2026-02-10', '2026-03-03', 2),
('L03', 'M01', 'S06', '2026-09-01', '2026-09-15', 2),
('L04', 'M03', 'S06', '2026-03-05', '2026-04-04', 1),
('L05', 'M04', 'S07', '2026-04-12', '2026-04-26', 1),
('L06', 'M01', 'S07', '2026-09-10', '2026-09-24', 1),
('L07', 'M05', 'S08', '2026-05-20', '2026-07-04', 1),
('L08', 'M06', 'S08', '2026-06-15', '2026-07-15', 1),
('L09', 'M07', 'S09', '2026-09-05', '2026-09-19', 1),
('L10', 'M08', 'S09', '2026-07-10', '2026-07-31', 1),
('L11', 'M09', 'S05', '2026-09-12', '2026-09-26', 1),
('L12', 'M10', 'S06', '2026-08-01', '2026-09-15', 1),
('L13', 'M11', 'S07', '2026-08-18', '2026-09-01', 1),
('L14', 'M12', 'S08', '2026-08-22', '2026-09-05', 1),
('L15', 'M13', 'S09', '2026-10-10', '2026-11-09', 1);

-- Book_Copy (21 rows)

INSERT INTO Book_Copy (Book_ID, Copy_ID, Shelf_Location, Status, Condition_Notes) VALUES
('B01', 'C01', 'Shelf A - Row 1', 'Available', 'Good condition'),
('B01', 'C02', 'Shelf A - Row 1', 'Available', 'New'),
('B02', 'C01', 'Shelf A - Row 2', 'Available', 'Cover slightly bent'),
('B02', 'C02', 'Shelf A - Row 2', 'Borrowed',  'Currently checked out on Loan L03'),
('B03', 'C01', 'Shelf B - Row 1', 'Reserved',  'Held at desk for reservation RES07'),  -- [D2] RES07 is the Confirmed one
('B03', 'C02', 'Shelf B - Row 1', 'Borrowed',  'Currently checked out on Loan L03'),
('B04', 'C01', 'Shelf B - Row 2', 'Available', 'Good condition'),
('B04', 'C02', 'Shelf B - Row 2', 'Lost',      'Reported missing in 2025'),
('B05', 'C01', 'Shelf C - Row 1', 'Available', 'Good condition'),
('B06', 'C01', 'Shelf C - Row 2', 'Damaged',   'Torn pages'),
('B06', 'C02', 'Shelf C - Row 2', 'Borrowed',  'Currently checked out on Loan L06'),
('B07', 'C01', 'Shelf D - Row 1', 'Available', 'New'),
('B08', 'C01', 'Shelf D - Row 2', 'Available', 'Good condition'),
('B09', 'C01', 'Shelf E - Row 1', 'Available', 'Good condition'),                     -- [D2] never lent, so B09 was never fully on loan
('B09', 'C02', 'Shelf E - Row 1', 'Borrowed',  'Currently checked out on Loan L09'),
('B10', 'C01', 'Shelf E - Row 2', 'Available', 'Cover slightly worn'),
('B11', 'C01', 'Shelf F - Row 1', 'Available', 'Good condition'),
('B12', 'C01', 'Shelf F - Row 2', 'Borrowed',  'Currently checked out on Loan L11'),
('B13', 'C01', 'Shelf F - Row 3', 'Borrowed',  'Currently checked out on Loan L15'),
('B14', 'C01', 'Shelf G - Row 1', 'Available', 'Brand New - Never Borrowed'),
('B15', 'C01', 'Shelf G - Row 2', 'Available', 'Brand New - Never Borrowed');

-- Reservation (15 rows)                                                     [D3]
-- Rewritten so that every row agrees with Book_Copy and Loan_Detail:
--   * each reservation was placed while no copy of the title could be lent
--     (every lendable copy out on loan or held for an earlier reservation),
--     as Topic 22 describes: "reservations for a title that is fully on loan";
--   * Confirmed = a copy of that title is held at the desk ('Reserved');
--   * Pending rows are on titles with no Available copy today (2026-10-24);
--   * Cancelled = not collected or withdrawn; the copy went back on the shelf;
--   * no row is Completed: no loan in Loan_Detail starts after a time when
--     every copy of its title was out, so no loan can be a reservation pick-up.
-- Only Active members reserve. These points describe the sample data; the
-- database does not enforce them (they are not among BR01-BR05).
INSERT INTO Reservation (Reservation_ID, Member_ID, Book_ID, Reservation_Date, Status) VALUES
('RES01', 'M11', 'B11', '2026-01-20', 'Cancelled'),  -- B11-C01 out on L01
('RES02', 'M04', 'B04', '2026-03-20', 'Cancelled'),  -- B04-C01 out on L04, B04-C02 lost
('RES03', 'M07', 'B05', '2026-04-20', 'Cancelled'),  -- B05-C01 out on L05
('RES04', 'M10', 'B07', '2026-06-01', 'Cancelled'),  -- B07-C01 out on L07
('RES05', 'M03', 'B08', '2026-07-01', 'Cancelled'),  -- B08-C01 out on L08
('RES06', 'M13', 'B10', '2026-07-20', 'Cancelled'),  -- B10-C01 out on L10
('RES07', 'M02', 'B03', '2026-09-02', 'Confirmed'),  -- both B03 copies out; C01 back 2026-09-04, held at desk
('RES08', 'M12', 'B02', '2026-09-03', 'Cancelled'),  -- both B02 copies out (L13, L03); C01 back 2026-09-06, not collected
('RES09', 'M05', 'B06', '2026-10-05', 'Pending'),    -- B06: C01 damaged, C02 out on L06
('RES10', 'M06', 'B12', '2026-10-06', 'Pending'),    -- B12-C01 out on L11
('RES11', 'M03', 'B03', '2026-10-09', 'Pending'),    -- B03: C01 held for RES07, C02 out on L03
('RES12', 'M08', 'B13', '2026-10-12', 'Pending'),    -- B13-C01 out on L15
('RES13', 'M12', 'B12', '2026-10-12', 'Pending'),    -- 2nd in the queue for B12
('RES14', 'M04', 'B06', '2026-10-14', 'Pending'),    -- 2nd in the queue for B06
('RES15', 'M11', 'B13', '2026-10-18', 'Pending');    -- 2nd in the queue for B13

-- Loan_Detail (18 rows)
-- [D4] Renewal_Count is 0 in every row: no loan below had its due date moved,
-- so no renewal happened (a renewal adds one loan period to the due date, see
-- Trigger 2). A renewal is shown in the CRUD block (L16).

INSERT INTO Loan_Detail (Loan_ID, Detail_ID, Book_ID, Copy_ID, Return_Date, Renewal_Count, Payment_Status, Fine_Amount) VALUES
('L01', 'D01', 'B01', 'C01', '2026-01-28', 0, 'None',   0.00),
('L01', 'D02', 'B11', 'C01', '2026-01-28', 0, 'None',   0.00),
('L02', 'D01', 'B01', 'C02', '2026-03-01', 0, 'None',   0.00),
('L02', 'D02', 'B02', 'C01', '2026-03-10', 0, 'Paid',   35000.00),  -- [D4] was 1
('L03', 'D01', 'B02', 'C02', NULL,         0, 'Unpaid', 45000.00),  -- [D4] was 1
('L03', 'D02', 'B03', 'C02', NULL,         0, 'Unpaid', 45000.00),
('L04', 'D01', 'B04', 'C01', '2026-04-12', 0, 'Unpaid', 40000.00),
('L05', 'D01', 'B05', 'C01', '2026-05-04', 0, 'Unpaid', 40000.00),
('L06', 'D01', 'B06', 'C02', NULL,         0, 'Unpaid', 25000.00),
('L07', 'D01', 'B07', 'C01', '2026-06-28', 0, 'None',   0.00),
('L08', 'D01', 'B08', 'C01', '2026-07-25', 0, 'Unpaid', 50000.00),  -- [D4] was 1
('L09', 'D01', 'B09', 'C02', NULL,         0, 'Unpaid', 40000.00),
('L10', 'D01', 'B10', 'C01', '2026-08-05', 0, 'Paid',   25000.00),
('L11', 'D01', 'B12', 'C01', NULL,         0, 'Unpaid', 35000.00),
('L12', 'D01', 'B01', 'C01', '2026-09-10', 0, 'None',   0.00),
('L13', 'D01', 'B02', 'C01', '2026-09-06', 0, 'Waived', 25000.00),
('L14', 'D01', 'B03', 'C01', '2026-09-04', 0, 'None',   0.00),
('L15', 'D01', 'B13', 'C01', NULL,         0, 'None',   0.00);



DROP TRIGGER IF EXISTS trigger_loantransaction_before_insertMember;
DROP TRIGGER IF EXISTS trg_before_loan_detail_insert_check_copy;
DROP TRIGGER IF EXISTS trg_loantransaction_before_update;       -- [T1]
DROP TRIGGER IF EXISTS trg_before_loan_detail_update_check;     -- [T3]
DROP TRIGGER IF EXISTS trg_staff_before_insert_hierarchy;       -- [T4]
DROP TRIGGER IF EXISTS trg_staff_before_update_hierarchy;       -- [T4]

DELIMITER $$

-- Trigger 1  Enforces BR03 on Loan_Transaction
CREATE TRIGGER trigger_loantransaction_before_insertMember
BEFORE INSERT ON Loan_Transaction
FOR EACH ROW
BEGIN
    DECLARE v_status       VARCHAR(20);
    DECLARE v_expiry       DATE;
    DECLARE v_limit        INT;
    DECLARE v_loan_period  INT;
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

        SELECT COUNT(*)
        INTO v_active_loans
        FROM Loan_Transaction lt
        INNER JOIN Loan_Detail ld
            ON lt.Loan_ID = ld.Loan_ID
        WHERE lt.Member_ID = NEW.Member_ID
          AND ld.Return_Date IS NULL;

        IF (v_active_loans + NEW.Total_Copies_Borrowed) > v_limit THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'BR03 Violation: Borrowing limit exceeded for this membership category.';
        END IF;
    END IF;
END$$

-- Trigger 2  [T1] Enforces BR03 on Loan_Transaction (changed due date or member)
--   Loan duration: an UPDATE may move Due_Date only within the category's loan
--   period, plus one more period for each renewal of the loan.
--   Borrowing limit: a loan handed to another member must fit that member's limit.
CREATE TRIGGER trg_loantransaction_before_update
BEFORE UPDATE ON Loan_Transaction
FOR EACH ROW
BEGIN
    DECLARE v_loan_period INT DEFAULT NULL;
    DECLARE v_limit       INT DEFAULT NULL;
    DECLARE v_renewals    INT DEFAULT 0;
    DECLARE v_open        INT DEFAULT 0;
    DECLARE v_moving      INT DEFAULT 0;

    SELECT mc.Loan_Period, mc.Borrowing_Limit
    INTO v_loan_period, v_limit
    FROM Member m
    INNER JOIN Member_Category mc
        ON m.Member_Type_ID = mc.Member_Type_ID
    WHERE m.Member_ID = NEW.Member_ID;

    IF NEW.Due_Date <> OLD.Due_Date
       OR NEW.Borrow_Date <> OLD.Borrow_Date
       OR NEW.Member_ID <> OLD.Member_ID THEN
        SELECT COALESCE(MAX(Renewal_Count), 0)
        INTO v_renewals
        FROM Loan_Detail
        WHERE Loan_ID = OLD.Loan_ID;

        IF DATEDIFF(NEW.Due_Date, NEW.Borrow_Date) > v_loan_period * (1 + v_renewals) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'BR03 Violation: Loan duration exceeds the loan period (plus renewals) for this membership category.';
        END IF;
    END IF;

    IF NEW.Member_ID <> OLD.Member_ID THEN
        SELECT COUNT(*)
        INTO v_open
        FROM Loan_Detail ld
        INNER JOIN Loan_Transaction lt
            ON ld.Loan_ID = lt.Loan_ID
        WHERE lt.Member_ID = NEW.Member_ID
          AND ld.Return_Date IS NULL;

        SELECT COUNT(*)
        INTO v_moving
        FROM Loan_Detail
        WHERE Loan_ID = OLD.Loan_ID
          AND Return_Date IS NULL;

        IF v_open + v_moving > v_limit THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'BR03 Violation: Borrowing limit exceeded for this membership category.';
        END IF;
    END IF;
END$$

-- Trigger 3  Enforces BR02 on Loan_Detail (new loan line)
--   [T2] BR05: a line entered as already returned after the due date must
--        carry a fine.
--   [T2] BR03: the borrowing limit is checked on the copies the member really
--        has out (Trigger 1 only sees the number the loan header claims).
CREATE TRIGGER trg_before_loan_detail_insert_check_copy
BEFORE INSERT ON Loan_Detail
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(50)  DEFAULT NULL;
    DECLARE v_msg    VARCHAR(128) DEFAULT NULL;
    DECLARE v_member VARCHAR(20)  DEFAULT NULL;   -- [T2]
    DECLARE v_due    DATE         DEFAULT NULL;   -- [T2]
    DECLARE v_limit  INT          DEFAULT NULL;   -- [T2]
    DECLARE v_open   INT          DEFAULT 0;      -- [T2]

    -- [T2] The loan this line belongs to: who borrows, the due date, the limit
    SELECT lt.Member_ID, lt.Due_Date, mc.Borrowing_Limit
    INTO v_member, v_due, v_limit
    FROM Loan_Transaction lt
    INNER JOIN Member m
        ON lt.Member_ID = m.Member_ID
    INNER JOIN Member_Category mc
        ON m.Member_Type_ID = mc.Member_Type_ID
    WHERE lt.Loan_ID = NEW.Loan_ID;

    -- [T2] BR05: returned after the due date, so a fine must be recorded
    IF NEW.Return_Date IS NOT NULL AND NEW.Return_Date > v_due AND NEW.Fine_Amount = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'BR05 Violation: A copy returned after its due date must carry a fine.';
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

        -- [T2] BR03: copies this member already has out, plus this one
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

-- Trigger 4  BEFORE UPDATE on Loan_Detail. 
--   BR05: a copy returned after its due date carries a fine;
--   BR03: a line that becomes open again (Return_Date set back to NULL) or is

CREATE TRIGGER trg_before_loan_detail_update_check
BEFORE UPDATE ON Loan_Detail
FOR EACH ROW
BEGIN
    DECLARE v_member VARCHAR(20) DEFAULT NULL;
    DECLARE v_due    DATE        DEFAULT NULL;
    DECLARE v_limit  INT         DEFAULT NULL;
    DECLARE v_open   INT         DEFAULT 0;

    SELECT lt.Member_ID, lt.Due_Date, mc.Borrowing_Limit
    INTO v_member, v_due, v_limit
    FROM Loan_Transaction lt
    INNER JOIN Member m
        ON lt.Member_ID = m.Member_ID
    INNER JOIN Member_Category mc
        ON m.Member_Type_ID = mc.Member_Type_ID
    WHERE lt.Loan_ID = NEW.Loan_ID;

    IF NEW.Return_Date IS NOT NULL AND NEW.Return_Date > v_due AND NEW.Fine_Amount = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'BR05 Violation: A copy returned after its due date must carry a fine.';
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

-- Triggers 5 and 6  [T4] Enforce BR04 on Staff. A hierarchy is a tree: the
--   "reports to" chain never comes back to where it started, and nobody
--   supervises themself (the FK alone only checks that the supervisor exists).
--   Why not a CHECK: MySQL forbids a CHECK on a column used by a foreign key
--   referential action (Supervisor_ID has ON DELETE SET NULL: error 3823),
--   and a cycle can only be seen by following the chain through other rows.
CREATE TRIGGER trg_staff_before_insert_hierarchy
BEFORE INSERT ON Staff
FOR EACH ROW
BEGIN
    -- A new row has no subordinates yet, so the only possible cycle is itself.
    IF NEW.Supervisor_ID = NEW.Staff_ID THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'BR04 Violation: A staff member cannot be their own supervisor.';
    END IF;
END$$

CREATE TRIGGER trg_staff_before_update_hierarchy
BEFORE UPDATE ON Staff
FOR EACH ROW
BEGIN
    DECLARE v_cycle INT DEFAULT 0;

    IF NEW.Supervisor_ID = NEW.Staff_ID THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'BR04 Violation: A staff member cannot be their own supervisor.';
    END IF;

    IF NEW.Supervisor_ID IS NOT NULL
       AND NOT (NEW.Supervisor_ID <=> OLD.Supervisor_ID) THEN
        -- Walk up the chain from the new supervisor. Meeting this staff member
        -- on the way means the new link would close a cycle. The walk ends at
        -- the top (Supervisor_ID IS NULL) because this trigger keeps the
        -- hierarchy free of cycles.
        WITH RECURSIVE chain (Staff_ID, Supervisor_ID) AS (
            SELECT Staff_ID, Supervisor_ID
            FROM Staff
            WHERE Staff_ID = NEW.Supervisor_ID
            UNION ALL
            SELECT s.Staff_ID, s.Supervisor_ID
            FROM Staff s
            INNER JOIN chain c
                ON s.Staff_ID = c.Supervisor_ID
        )
        SELECT COUNT(*)
        INTO v_cycle
        FROM chain
        WHERE Staff_ID = OLD.Staff_ID;

        IF v_cycle > 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'BR04 Violation: This change would create a cycle in the supervision hierarchy.';
        END IF;
    END IF;
END$$

DELIMITER ;



-- 1. CRUD for Member_Category
INSERT INTO Member_Category (Member_Type_ID, Type_Name, Borrowing_Limit, Loan_Period)
VALUES ('MC16', 'Short-Term Research Visitor', 4, 14);
UPDATE Member_Category
SET Borrowing_Limit = 5, Loan_Period = 21
WHERE Member_Type_ID = 'MC16';
DELETE FROM Member_Category
WHERE Member_Type_ID = 'MC16';
-- 2 & 3. CRUD for Member & Member_Phone
INSERT INTO Member (Member_ID, Member_Type_ID, Full_Name, Email, Identity_Card, Membership_Expiry_Date, Account_Status)
VALUES ('M16', 'MC01', 'Nguyen Minh Tri', 'nmtri@hcmiu.edu.vn', '079205001016', '2027-08-31', 'Active');
INSERT INTO Member_Phone (Member_ID, Phone)
VALUES ('M16', '0909998816');
UPDATE Member_Phone
SET Phone = '0909998877'
WHERE Member_ID = 'M16' AND Phone = '0909998816';
DELETE FROM Member_Phone
WHERE Member_ID = 'M16' AND Phone = '0909998877';
UPDATE Member
SET Account_Status = 'Suspended', Membership_Expiry_Date = '2028-08-31'
WHERE Member_ID = 'M16';
DELETE FROM Member
WHERE Member_ID = 'M16';
-- 4. CRUD for Category
INSERT INTO Category (Category_ID, Category_Name, Description)
VALUES ('CAT16', 'Data Science', 'Big data analytics, data mining, and visualization.');
UPDATE Category
SET Description = 'Big data analytics, statistical modeling, and visualization.'
WHERE Category_ID = 'CAT16';
DELETE FROM Category
WHERE Category_ID = 'CAT16';
-- 5. CRUD for Publisher
INSERT INTO Publisher (Publisher_ID, Publisher_Name, Address, Contact_Email)
VALUES ('PUB16', 'Addison-Wesley', 'Boston, MA, USA', 'contact@aw.com');
UPDATE Publisher
SET Address = 'Boston, Massachusetts, USA'
WHERE Publisher_ID = 'PUB16';
DELETE FROM Publisher
WHERE Publisher_ID = 'PUB16';
-- 6. CRUD for Author
INSERT INTO Author (Author_ID, Author_Name, Biography)
VALUES ('AUTH19', 'Andrew S. Tanenbaum', 'Professor Emeritus of Computer Science at Vrije Universiteit Amsterdam.');
UPDATE Author
SET Biography = 'Author of Modern Operating Systems and Computer Networks.'
WHERE Author_ID = 'AUTH19';
DELETE FROM Author
WHERE Author_ID = 'AUTH19';
-- 7, 8, 11 & 12. CRUD for Book, Book_Author, Book_Copy & Reservation
INSERT INTO Book (Book_ID, Category_ID, Publisher_ID, ISBN, Title, Publication_Year)
VALUES ('B16', 'CAT01', 'PUB01', '978-0262046305', 'Introduction to Algorithms, 4th Edition', 2022);
UPDATE Book
SET Title = 'Introduction to Algorithms (4th Ed.)', Publication_Year = 2022, Category_ID = 'CAT02'
WHERE Book_ID = 'B16';
INSERT INTO Book_Author (Book_ID, Author_ID, Author_Order)
VALUES ('B16', 'AUTH01', 1);
UPDATE Book_Author
SET Author_Order = 2
WHERE Book_ID = 'B16' AND Author_ID = 'AUTH01';
DELETE FROM Book_Author
WHERE Book_ID = 'B16' AND Author_ID = 'AUTH01';
INSERT INTO Book_Copy (Book_ID, Copy_ID, Shelf_Location, Status, Condition_Notes)
VALUES ('B16', 'C01', 'Shelf A - Row 3', 'Available', 'New'),
       ('B16', 'C02', 'Shelf A - Row 3', 'Available', 'New');
UPDATE Book_Copy
SET Status = 'Damaged', Condition_Notes = 'Water damage on cover'
WHERE Book_ID = 'B16' AND Copy_ID = 'C02';
-- [C2] The demo reserves B12, whose only copy is out on loan (B16-C01 is on
-- the shelf, so B16 is not fully on loan), and then cancels it ('Confirmed'
-- would mean a copy is held at the desk, and none is).
INSERT INTO Reservation (Reservation_ID, Member_ID, Book_ID, Reservation_Date, Status)
VALUES ('RES16', 'M02', 'B12', '2026-10-23', 'Pending');
UPDATE Reservation
SET Status = 'Cancelled'
WHERE Reservation_ID = 'RES16';
DELETE FROM Reservation
WHERE Reservation_ID = 'RES16';
DELETE FROM Book_Copy
WHERE Book_ID = 'B16' AND Copy_ID = 'C02';
DELETE FROM Book_Copy
WHERE Book_ID = 'B16' AND Copy_ID = 'C01';
DELETE FROM Book
WHERE Book_ID = 'B16';
-- 9. CRUD for Staff
INSERT INTO Staff (Staff_ID, Supervisor_ID, Full_Name, Position, Email)
VALUES ('S16', 'S03', 'Pham Hoang Nam', 'Assistant Circulation Librarian', 'phnam@hcmiu.edu.vn');
UPDATE Staff
SET Position = 'Circulation Librarian', Supervisor_ID = 'S02'
WHERE Staff_ID = 'S16';
DELETE FROM Staff
WHERE Staff_ID = 'S16';
-- 10 & 13. CRUD for Loan_Transaction & Loan_Detail
INSERT INTO Loan_Transaction (Loan_ID, Member_ID, Staff_ID, Borrow_Date, Due_Date, Total_Copies_Borrowed)
VALUES ('L16', 'M04', 'S05', '2026-10-20', '2026-11-03', 1);
INSERT INTO Loan_Detail (Loan_ID, Detail_ID, Book_ID, Copy_ID, Return_Date, Renewal_Count, Payment_Status, Fine_Amount)
VALUES ('L16', 'D01', 'B14', 'C01', NULL, 0, 'None', 0.00);
-- [C1] Renew first, then extend, then return: Trigger 2 allows one more loan
-- period per renewal, so the due date can move only after Renewal_Count is 1.
UPDATE Loan_Detail
SET Renewal_Count = 1
WHERE Loan_ID = 'L16' AND Detail_ID = 'D01';
UPDATE Loan_Transaction
SET Due_Date = '2026-11-17'
WHERE Loan_ID = 'L16';
UPDATE Loan_Detail
SET Return_Date = '2026-11-10'
WHERE Loan_ID = 'L16' AND Detail_ID = 'D01';
DELETE FROM Loan_Detail
WHERE Loan_ID = 'L16' AND Detail_ID = 'D01';
DELETE FROM Loan_Transaction
WHERE Loan_ID = 'L16';

--  TRANSACTION 1 (COMMIT): Atomic Book Checkout across 3 tables
START TRANSACTION;

INSERT INTO Loan_Transaction (Loan_ID, Member_ID, Staff_ID, Borrow_Date, Due_Date, Total_Copies_Borrowed)
VALUES ('L17', 'M04', 'S05', '2026-10-20', '2026-11-03', 1);

INSERT INTO Loan_Detail (Loan_ID, Detail_ID, Book_ID, Copy_ID, Return_Date, Renewal_Count, Payment_Status, Fine_Amount)
VALUES ('L17', 'D01', 'B14', 'C01', NULL, 0, 'None', 0.00);

UPDATE Book_Copy
SET Status = 'Borrowed',
    Condition_Notes = 'Checked out under Loan L17'
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
SET Status = 'Available', Condition_Notes = 'Brand New - Never Borrowed'
WHERE Book_ID = 'B14' AND Copy_ID = 'C01';
COMMIT;
