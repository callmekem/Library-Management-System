SET NAMES utf8mb4;
SET SESSION sql_mode = 'STRICT_ALL_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

DROP DATABASE IF EXISTS Library_Management_db;
CREATE DATABASE Library_Management_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE library_management_db;
--  BR01:Aphysical book copy (Book_Copy) cannot exist independently being associated with a parent book title (Book).

--  BR02: Book reservations (Reservation) are placed on a specific Book (title) ,whereas active loans (Loan_Detail) are tracked by physical book copies(Book_Copy).

-- BR03: Member borrowing privileges (limits and loan durations) are strictly governed by their membership category (Member_Category).

-- BR04: Staff members operate under an organizational hierarchy where a staff member may report to a designated supervisor (Staff self-reference).

-- BR05: Overdue books incur fines which are tracked for each specific borrowed copy in the Loan_Detail table, along with their payment statuses

-- 1 Member category 
 -- Enforces BR03: Defines borrowing limits and loan durations per tier
CREATE TABLE Member_Category (
    Member_Type_ID VARCHAR(20) NOT NULL,
    Type_Name VARCHAR(50) NOT NULL,
    Borrowing_Limit INT NOT NULL DEFAULT 3,
    Loan_Period INT NOT NULL DEFAULT 14,
    CONSTRAINT PK_Member_Category PRIMARY KEY (Member_Type_ID),
    CONSTRAINT unique_Membr_Category_TypeName UNIQUE(Type_Name), 
    CONSTRAINT check_MemberCategoryLimit CHECK (Borrowing_Limit BETWEEN 1 AND  20 AND Loan_Period BETWEEN 1 AND 90)  -- moi vai loai thanh vienn co the muon tu 1 den 20 quyen sach 
    -- thoi han la tu 1 den 90 ngay
)ENGINE=InnoDB;

-- 2. Member
-- Enforces BR03: Every member belongs to a valid Member_Category

CREATE TABLE Member (
    Member_ID VARCHAR (20) NOT NULL, -- PK
    Member_Type_ID VARCHAR(20) NOT NULL, -- FK
    FullName VARCHAR (100) NOT NULL,
    Email VARCHAR (200) NOT NULL,
    Identity_Card VARCHAR (20) NOT NULL,
    Membership_Expiry_Date DATE NOT NULL,
    Account_Status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    CONSTRAINT PK_Member PRIMARY KEY (Member_ID),
    CONSTRAINT unique_MemberEmail UNIQUE (Email),
    CONSTRAINT unique_MemberIdentityCard UNIQUE (Identity_Card),
    CONSTRAINT FK_Memberbelongto_category FOREIGN KEY (Member_Type_ID) REFERENCES Member_Category (Member_Type_ID)
    ON DELETE RESTRICT ON UPDATE CASCADE, -- không cho xóa cột Member_Type_ID ở bản cha khi có bản con tham chiếu đến và có thể update thay đổi được
    CONSTRAINT check_Emailformat CHECK (Email LIKE '%_@__%.__%'),
    CONSTRAINT check_Member_AccountStatus CHECK (Account_Status IN('Active','Suspended','Expired','Locked'))

)ENGINE=InnoDB;
-- 3. Member_Phone
-- Resolves multivalued attribute Phone of Member

CREATE TABLE Member_Phone (
    Member_ID VARCHAR(20) NOT NULL,
    Phone     VARCHAR(20) NOT NULL,
    CONSTRAINT pk_member_phone
        PRIMARY KEY (Member_ID, Phone),
    CONSTRAINT fk_member_phone_has_phone FOREIGN KEY (Member_ID) REFERENCES Member (Member_ID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT check_Memberphonelength
        CHECK (CHAR_LENGTH(Phone) BETWEEN 8 AND 20)
) ENGINE=InnoDB;

CREATE TABLE Category (
    Category_ID VARCHAR(50) PRIMARY KEY,
    Category_Name VARCHAR(100) NOT NULL UNIQUE,
    Description TEXT
);

CREATE TABLE Publisher (
  Publisher_ID   VARCHAR(50)  NOT NULL,
  Publisher_Name VARCHAR(150) NOT NULL,
  Address        VARCHAR(255) NULL,
  Contact_Email  VARCHAR(100) NULL,
  PRIMARY KEY (Publisher_ID),
  CONSTRAINT uq_publisher_name UNIQUE (Publisher_Name)
);

CREATE TABLE Author (
  Author_ID   VARCHAR(50)  NOT NULL,
  Author_Name VARCHAR(150) NOT NULL,
  Biography   TEXT         NULL,
  PRIMARY KEY (Author_ID)
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

-- 4. Staff
-- Enforces BR04: Organizational hierarchy via recursive self-referencing FK

CREATE TABLE Staff (
    Staff_ID VARCHAR (20) NOT NULL, -- PK
    Supervisor_ID VARCHAR (20) NULL DEFAULT  NULL, -- FK
    Full_Name VARCHAR (100) NOT NULL,
    Position VARCHAR(50)  NOT NULL DEFAULT  'Librarian',
    Email VARCHAR(200) NOT NULL,
    CONSTRAINT PK_Staff PRIMARY KEY (Staff_ID),
    CONSTRAINT unique_staffemail UNIQUE (Email),
    CONSTRAINT FK_staffSupervisor FOREIGN KEY (Supervisor_ID) REFERENCES Staff (Staff_ID)
    ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT check_staffemailformat CHECK (Email LIKE '%_@__%.__%')

)ENGINE=InnoDB;
-- Loan_Transaction
-- Header table for a borrowing transaction handled by a Staff member.

CREATE TABLE  Loan_Transaction (
    Loan_ID VARCHAR(20) NOT NULL ,
    Member_ID VARCHAR(20) NOT NULL,
    Staff_ID VARCHAR(20) NOT NULL,
    Borrow_Date DATE NOT NULL DEFAULT (CURRENT_DATE),
    Due_Date DATE NOT NULL, 
    Total_Copies_Borrowed int NOT NULL DEFAULT 1,
    CONSTRAINT PK_Loantransaction PRIMARY KEY (Loan_ID),
    CONSTRAINT FK_loantransactionMakeMember FOREIGN KEY (Member_ID) REFERENCES MEMBER (Member_ID)
    ON DELETE RESTRICT ON UPDATE CASCADE ,
    CONSTRAINT FK_loanhandlesStaffID FOREIGN KEY  (Staff_ID) REFERENCES Staff (Staff_ID)
    ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT check_loantransactionDate  CHECK (Due_Date >=Borrow_Date), -- ngay hen tra luon dien ra sau hoac cung ngay muon
    CONSTRAINT check_loantransaction_totalcopies CHECK (Total_Copies_Borrowed BETWEEN 1 AND 20)
)ENGINE=InnoDB;

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
--  Loan_Detail (Weak entity)
-- Enforces BR02 & BR05: Links to physical copy (Book_ID, Copy_ID) and tracks fines

CREATE TABLE Loan_Detail ( 
    Loan_ID VARCHAR (20) NOT NULL,
    Detail_ID VARCHAR(20) NOT NULL,
    Book_ID VARCHAR(20) NOT NULL,
    Copy_ID VARCHAR (20) NOT NULL,
    Return_DATE DATE  NULL DEFAULT NULL ,
    Renewal_Count INT NOT NULL DEFAULT 0,
    Payment_Status VARCHAR (20) NOT NULL DEFAULT 'NONE',
    Fine_Amount DECIMAL (10,2)  NOT NULL DEFAULT 0.00, -- tien phat ma ng doc phai nop
    CONSTRAINT PK_LoanDetail PRIMARY KEY (Loan_ID,Detail_ID),
    CONSTRAINT FK_loanDetai_lbelongto_loanID FOREIGN KEY (Loan_ID) REFERENCES Loan_Transaction (Loan_ID)
    ON DELETE CASCADE ON UPDATE CASCADE ,
    CONSTRAINT unique_loandetail_copy_per_loan UNIQUE (Loan_ID,Book_ID,Copy_ID), -- dam bao trong 1 lan muon thi cuon sach vat ly cu the xuat hien dung 1 lan
    CONSTRAINT FK_loandetail_borrwed_BookCopy FOREIGN KEY (Book_ID ,Copy_ID) REFERENCES Book_Copy(Book_ID,Copy_ID)
    ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT check_loandetail_renewalcount CHECK (Renewal_Count BETWEEN 0 AND 5),
    CONSTRAINT check_loandetail_fine_amount CHECK (Fine_Amount >=0.00),
    CONSTRAINT check_loandetail_paymentstatus CHECK (Payment_Status IN ('NONE', 'UNPAID','PAID', 'Waived' ) AND (Fine_Amount =0.00 AND Payment_Status='NONE') OR (Fine_Amount >0.00 AND Payment_Status IN ('UNPAID','PAID','Waived')))

)ENGINE=InnoDB;
-- Create Index for query optimization 

-- Indexes for Circulation & Fine queries (query 2 ,3 ,5)
CREATE INDEX index_loanTransaction_member_due    ON Loan_Transaction (Member_ID, Due_Date);

CREATE INDEX idx_loan_detail_return_date  ON Loan_Detail (Return_Date);

CREATE INDEX idx_loantransaction_borrow_date      ON Loan_Transaction (Borrow_Date);

CREATE INDEX idx_loan_detail_payment_fine ON Loan_Detail (Payment_Status, Fine_Amount);
UPDATE Book_Copy bc
SET bc.Status = 'Available'
WHERE bc.Status = 'Borrowed'
  AND NOT EXISTS (SELECT 1 FROM Loan_Detail ld
                  WHERE ld.Book_ID = bc.Book_ID
                    AND ld.Copy_ID = bc.Copy_ID
                    AND ld.Return_Date IS NULL);

SET SQL_SAFE_UPDATES = @old_safe_updates;


SELECT bc.Book_ID, bc.Copy_ID, bc.Status AS Copy_Status,
       (SELECT COUNT(*) FROM Loan_Detail ld
         WHERE ld.Book_ID = bc.Book_ID AND ld.Copy_ID = bc.Copy_ID
           AND ld.Return_Date IS NULL) AS Open_Loans
FROM Book_Copy bc
WHERE (bc.Status = 'Borrowed')
      <> (EXISTS (SELECT 1 FROM Loan_Detail ld
                  WHERE ld.Book_ID = bc.Book_ID AND ld.Copy_ID = bc.Copy_ID
                    AND ld.Return_Date IS NULL));


-- PART 1. INDEXES (3)
SET @ddl = IF((SELECT COUNT(*) FROM information_schema.statistics
                WHERE table_schema = DATABASE() AND LOWER(table_name) = 'book'
                  AND index_name = 'idx_book_title') = 0,
              'CREATE INDEX idx_book_title ON Book (Title)', 'DO 0');
PREPARE ddl_stmt FROM @ddl;
EXECUTE ddl_stmt;
DEALLOCATE PREPARE ddl_stmt;

SET @ddl = IF((SELECT COUNT(*) FROM information_schema.statistics
                WHERE table_schema = DATABASE() AND LOWER(table_name) = 'book_copy'
                  AND index_name = 'idx_book_copy_status') = 0,
              'CREATE INDEX idx_book_copy_status ON Book_Copy (Status, Book_ID)', 'DO 0');
PREPARE ddl_stmt FROM @ddl;
EXECUTE ddl_stmt;
DEALLOCATE PREPARE ddl_stmt;

-- Query 4 (find books by author name)
SET @ddl = IF((SELECT COUNT(*) FROM information_schema.statistics
                WHERE table_schema = DATABASE() AND LOWER(table_name) = 'author'
                  AND index_name = 'idx_author_name') = 0,
              'CREATE INDEX idx_author_name ON Author (Author_Name)', 'DO 0');
PREPARE ddl_stmt FROM @ddl;
EXECUTE ddl_stmt;
DEALLOCATE PREPARE ddl_stmt;

-- Verify
SHOW INDEX FROM Book      WHERE Key_name = 'idx_book_title';
SHOW INDEX FROM Book_Copy WHERE Key_name = 'idx_book_copy_status';
SHOW INDEX FROM Author    WHERE Key_name = 'idx_author_name';
INSERT INTO Member_Category (Member_Type_ID,Type_Name,Borrowing_Limit,Loan_Period) VALUES
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

INSERT INTO Member (Member_ID,Member_Type_ID,FullName,Email,Identity_Card,Membership_Expiry_Date,Account_Status) VALUES
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


INSERT INTO Member_Phone (Member_ID,Phone) VALUES 
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

INSERT INTO Publisher (Publisher_ID, Publisher_Name, Address, Contact_Email) VALUES
('PUB01', 'MIT Press', 'Cambridge, MA, USA', 'info@mitpress.mit.edu'),
('PUB02', 'Prentice Hall', 'Upper Saddle River, NJ, USA', 'contact@prenticehall.com'),
('PUB03', 'O Reilly Media', 'Sebastopol, CA, USA', 'support@oreilly.com'),
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

INSERT INTO Staff (Staff_ID,Supervisor_ID,Full_Name,Position,Email) VALUES 
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

INSERT INTO Loan_Transaction (Loan_ID,Member_ID,Staff_ID,Borrow_Date,Due_Date,Total_Copies_Borrowed) VALUES 
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
('L15', 'M13', 'S09', '2026-10-10', '2026-12-15', 1);

INSERT INTO Book_Copy (Book_ID, Copy_ID, Shelf_Location, Status, Condition_Notes) VALUES
('B01', 'C01', 'Shelf A - Row 1', 'Borrowed',  'Good condition'),
('B01', 'C02', 'Shelf A - Row 1', 'Available', 'New'),
('B02', 'C01', 'Shelf A - Row 2', 'Borrowed',  'Cover slightly bent'),
('B02', 'C02', 'Shelf A - Row 2', 'Available', 'Good condition'),
('B03', 'C01', 'Shelf B - Row 1', 'Reserved',  'Good condition'),
('B03', 'C02', 'Shelf B - Row 1', 'Available', 'Pages yellowed'),
('B04', 'C01', 'Shelf B - Row 2', 'Lost',      'Reported missing in 2025'),
('B05', 'C01', 'Shelf C - Row 1', 'Borrowed',  'Good condition'),
('B06', 'C01', 'Shelf C - Row 2', 'Damaged',   'Torn pages'),
('B07', 'C01', 'Shelf D - Row 1', 'Available', 'New'),
('B08', 'C01', 'Shelf D - Row 2', 'Available', 'Good condition'),
('B09', 'C01', 'Shelf E - Row 1', 'Reserved',  'Good condition'),
('B10', 'C01', 'Shelf E - Row 2', 'Borrowed',  'Cover damaged'),
('B11', 'C01', 'Shelf F - Row 1', 'Available', 'Good condition'),
('B12', 'C01', 'Shelf F - Row 2', 'Available', 'New'),
('B13', 'C01', 'Shelf F - Row 3', 'Available', 'Good condition'),
('B14', 'C01', 'Shelf G - Row 1', 'Available', 'Brand New - Never Borrowed'),
('B15', 'C01', 'Shelf G - Row 2', 'Available', 'Brand New - Never Borrowed');

	




INSERT INTO Reservation (Reservation_ID, Member_ID, Book_ID, Reservation_Date, Status) VALUES
('RES01', 'M01', 'B01', '2026-10-01', 'Pending'),
('RES02', 'M02', 'B02', '2026-10-02', 'Confirmed'),
('RES03', 'M03', 'B03', '2026-10-03', 'Completed'),
('RES04', 'M04', 'B04', '2026-10-04', 'Cancelled'),
('RES05', 'M05', 'B05', '2026-10-05', 'Pending'),
('RES06', 'M06', 'B06', '2026-10-06', 'Confirmed'),
('RES07', 'M07', 'B07', '2026-10-07', 'Completed'),
('RES08', 'M08', 'B08', '2026-10-08', 'Pending'),
('RES09', 'M09', 'B09', '2026-10-09', 'Confirmed'),
('RES10', 'M10', 'B10', '2026-10-10', 'Completed'),
('RES11', 'M11', 'B11', '2026-10-11', 'Cancelled'),
('RES12', 'M12', 'B12', '2026-10-12', 'Pending'),
('RES13', 'M13', 'B13', '2026-10-13', 'Confirmed'),
('RES14', 'M14', 'B14', '2026-10-14', 'Pending'),
('RES15', 'M15', 'B15', '2026-10-15', 'Completed');

INSERT INTO Loan_Detail (Loan_ID,Detail_ID,Book_ID,Copy_ID,Return_Date,Renewal_Count,Payment_Status,Fine_Amount) VALUES
('L01', 'D01', 'B01', 'C01', '2026-01-28', 0, 'None',   0.00),
('L01', 'D02', 'B11', 'C01', '2026-01-28', 0, 'None',   0.00),
('L02', 'D01', 'B01', 'C02', '2026-03-01', 0, 'None',   0.00),
('L02', 'D02', 'B11', 'C01', '2026-03-10', 1, 'Paid',   35000.00),
('L03', 'D01', 'B02', 'C02', NULL,         1, 'Unpaid', 45000.00),
('L03', 'D02', 'B03', 'C02', NULL,         0, 'Unpaid', 45000.00),
('L04', 'D01', 'B04', 'C01', '2026-04-12', 0, 'Unpaid', 40000.00),
('L05', 'D01', 'B05', 'C01', '2026-05-04', 0, 'Unpaid', 40000.00),
('L06', 'D01', 'B06', 'C01', NULL,         0, 'Unpaid', 25000.00),
('L07', 'D01', 'B07', 'C01', '2026-06-28', 0, 'None',   0.00),
('L08', 'D01', 'B08', 'C01', '2026-07-25', 1, 'Unpaid', 50000.00),
('L09', 'D01', 'B09', 'C01', NULL,         0, 'Unpaid', 40000.00),
('L10', 'D01', 'B10', 'C01', '2026-08-05', 0, 'Paid',   25000.00),
('L11', 'D01', 'B12', 'C01', NULL,         0, 'Unpaid', 35000.00),
('L12', 'D01', 'B01', 'C01', '2026-09-10', 0, 'None',   0.00),
('L13', 'D01', 'B02', 'C01', '2026-09-06', 0, 'Waived', 25000.00),
('L14', 'D01', 'B03', 'C01', '2026-09-04', 0, 'None',   0.00),
('L15', 'D01', 'B13', 'C01', NULL,         0, 'None',   0.00);
DELIMITER $$ 
CREATE TRIGGER trigger_loantransaction_before_insertMember BEFORE INSERT ON Loan_Transaction FOR EACH  ROW 
BEGIN 
-- khai bao cac bien 
 DECLARE v_status      VARCHAR(20); -- account status 
    DECLARE v_expiry      DATE; -- member ship expiry date
    DECLARE v_limit       INT; -- borrowing limit 
    DECLARE v_loan_period INT; -- loan period 
    DECLARE v_active_loans INT;
     SELECT m.Account_Status, m.Membership_Expiry_Date,
           mc.Borrowing_Limit, mc.Loan_Period
    INTO v_status, v_expiry, v_limit, v_loan_period -- INTO NAY LA DE CHO ta select các cột sẽ lưu vào theo thứ tự v_status...
    FROM Member m
    INNER JOIN Member_Category mc
        ON m.Member_Type_ID = mc.Member_Type_ID
    WHERE m.Member_ID = NEW.Member_ID;
      IF v_status IS NOT NULL THEN
        IF v_status <> 'Active' THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'BR03 Violation: Member account is not Active and cannot borrow books.';
        END IF;
        IF v_expiry < NEW.Borrow_Date THEN -- neu the thanh vien het han truoc ngay mượn sách của giao dịch loan mới 
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
    END IF; -- dem so luong sach chưa trả nếu quá lượt mượn thì k cho mượn nữa 
END$$
-- PART 2. TRIGGER (BR02)
DROP TRIGGER IF EXISTS trg_before_loan_detail_insert_check_copy;

DELIMITER $$
CREATE TRIGGER trg_before_loan_detail_insert_check_copy
BEFORE INSERT ON Loan_Detail
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(50)  DEFAULT NULL;
    DECLARE v_msg    VARCHAR(128) DEFAULT NULL;

    IF NEW.Return_Date IS NULL THEN
        SELECT Status INTO v_status
        FROM Book_Copy
        WHERE Book_ID = NEW.Book_ID AND Copy_ID = NEW.Copy_ID;

        IF v_status IS NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Cannot lend: this book copy does not exist.';
        ELSEIF v_status NOT IN ('Available', 'Reserved') THEN
          
            SET v_msg = CONCAT('Cannot lend: this copy is not available (status: ', v_status, ').');
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = v_msg;
        END IF;
    END IF;
END$$
DELIMITER ;

SHOW TRIGGERS LIKE 'Loan_Detail';
-- CRUD for Member

INSERT INTO Member (Member_ID, Member_Type_ID, FullName, Email, Identity_Card, Membership_Expiry_Date, Account_Status)
VALUES ('M16', 'MC01', 'Nguyen Minh Tri', 'nmtri@hcmiu.edu.vn', '079205001016', '2027-08-31', 'Active');
UPDATE Member
SET Account_Status = 'Suspended', Membership_Expiry_Date = '2028-08-31'
WHERE Member_ID = 'M16';
DELETE FROM Member
WHERE Member_ID = 'M16';
-- CRUD for Staff
INSERT INTO Staff (Staff_ID, Supervisor_ID, Full_Name, Position, Email)
VALUES ('S16', 'S03', 'Pham Hoang Nam', 'Assistant Circulation Librarian', 'phnam@hcmiu.edu.vn');
UPDATE Staff
SET Position = 'Circulation Librarian', Supervisor_ID = 'S02'
WHERE Staff_ID = 'S16';
DELETE FROM Staff
WHERE Staff_ID = 'S16';
-- PART 3. CRUD on Book, Book_Copy, Reservation
-- ---------- Book ----------
INSERT INTO Book (Book_ID, Category_ID, Publisher_ID, ISBN, Title, Publication_Year)
VALUES ('B16', 'CAT01', 'PUB01', '978-0262046305', 'Introduction to Algorithms, 4th Edition', 2022);

SELECT * FROM Book WHERE Book_ID = 'B16';

UPDATE Book
SET Title = 'Introduction to Algorithms (4th Ed.)', Publication_Year = 2022, Category_ID = 'CAT02'
WHERE Book_ID = 'B16';

-- ---------- Book_Copy ----------
INSERT INTO Book_Copy (Book_ID, Copy_ID, Shelf_Location, Status, Condition_Notes)
VALUES ('B16', 'C01', 'Shelf A - Row 3', 'Available', 'New'),
       ('B16', 'C02', 'Shelf A - Row 3', 'Available', 'New');

UPDATE Book_Copy
SET Status = 'Damaged', Condition_Notes = 'Water damage on cover'
WHERE Book_ID = 'B16' AND Copy_ID = 'C02';

-- ---------- Reservation ----------
INSERT INTO Reservation (Reservation_ID, Member_ID, Book_ID, Reservation_Date, Status)
VALUES ('RES16', 'M02', 'B16', '2026-10-23', 'Pending');

UPDATE Reservation SET Status = 'Confirmed' WHERE Reservation_ID = 'RES16';

SELECT r.Reservation_ID, m.FullName, b.Title, r.Status
FROM Reservation r
JOIN Member m ON m.Member_ID = r.Member_ID
JOIN Book   b ON b.Book_ID   = r.Book_ID
WHERE r.Reservation_ID = 'RES16';

-- ---------- DELETE (clean up) ----------
DELETE FROM Reservation WHERE Reservation_ID = 'RES16';
DELETE FROM Book_Copy   WHERE Book_ID = 'B16' AND Copy_ID = 'C02';
DELETE FROM Book        WHERE Book_ID = 'B16';       

SELECT COUNT(*) AS Remaining_B16_Copies FROM Book_Copy WHERE Book_ID = 'B16';  
-- CRUD for Loan_Transaction and Loan_Detail
INSERT INTO Loan_Transaction (Loan_ID, Member_ID, Staff_ID, Borrow_Date, Due_Date, Total_Copies_Borrowed)
VALUES ('L16', 'M04', 'S05', '2026-10-20', '2026-11-03', 1);
INSERT INTO Loan_Detail (Loan_ID, Detail_ID, Book_ID, Copy_ID, Return_Date, Renewal_Count, Payment_Status, Fine_Amount)
VALUES ('L16', 'D01', 'B14', 'C01', NULL, 0, 'None', 0.00);
--  Renewal: extends Due_Date by exactly one MC01 Loan_Period (+14 days),
--         and Renewal_Count records that one renewal was granted
UPDATE Loan_Transaction
SET Due_Date = '2026-11-17'
WHERE Loan_ID = 'L16';
UPDATE Loan_Detail
SET Renewal_Count = 1, Return_Date = '2026-11-10'
WHERE Loan_ID = 'L16' AND Detail_ID = 'D01';
DELETE FROM Loan_Detail
WHERE Loan_ID = 'L16' AND Detail_ID = 'D01';
DELETE FROM Loan_Transaction
WHERE Loan_ID = 'L16';
-- Transaction 1 commit :Atomic Book Checkout across  3 tables
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
SELECT 'BEFORE' AS Step, ld.Loan_ID, ld.Detail_ID, ld.Return_Date, ld.Payment_Status,
       ld.Fine_Amount, bc.Status AS Copy_Status
FROM Loan_Detail ld
JOIN Book_Copy bc ON bc.Book_ID = ld.Book_ID AND bc.Copy_ID = ld.Copy_ID
WHERE ld.Loan_ID = 'L03' AND ld.Detail_ID = 'D01';

START TRANSACTION;

    -- 1. Record the return
    UPDATE Loan_Detail
    SET Return_Date = CURDATE()
    WHERE Loan_ID = 'L03' AND Detail_ID = 'D01' AND Return_Date IS NULL;

    -- 2. Pay the fine
    UPDATE Loan_Detail
    SET Payment_Status = 'Paid'
    WHERE Loan_ID = 'L03' AND Detail_ID = 'D01';

    -- 3. Release the physical copy
    UPDATE Book_Copy
    SET Status = 'Available'
    WHERE Book_ID = 'B02' AND Copy_ID = 'C02';

    -- State INSIDE the transaction (changes visible only to this session)
    SELECT 'INSIDE TRANSACTION' AS Step, ld.Loan_ID, ld.Detail_ID, ld.Return_Date, ld.Payment_Status,
           ld.Fine_Amount, bc.Status AS Copy_Status
    FROM Loan_Detail ld
    JOIN Book_Copy bc ON bc.Book_ID = ld.Book_ID AND bc.Copy_ID = ld.Copy_ID
    WHERE ld.Loan_ID = 'L03' AND ld.Detail_ID = 'D01';

    -- 4. Payment gateway reports FAILURE -> undo everything (Atomicity)
ROLLBACK;

-- State AFTER: identical to BEFORE
SELECT 'AFTER ROLLBACK' AS Step, ld.Loan_ID, ld.Detail_ID, ld.Return_Date, ld.Payment_Status,
       ld.Fine_Amount, bc.Status AS Copy_Status
FROM Loan_Detail ld
JOIN Book_Copy bc ON bc.Book_ID = ld.Book_ID AND bc.Copy_ID = ld.Copy_ID
WHERE ld.Loan_ID = 'L03' AND ld.Detail_ID = 'D01';

