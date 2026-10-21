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
    Type_Name VARCHAR(20) NOT NULL,
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
    CONSTRAINT check_Member_AccountStatus CHECK (Account_Status IN('Acitve','Suspended','Expired','Locked'))

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