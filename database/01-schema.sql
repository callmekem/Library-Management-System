SET NAMES utf8mb4;
SET SESSION sql_mode = 'STRICT_ALL_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

DROP DATABASE IF EXISTS Library_Management_db;
CREATE DATABASE Library_Management_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE library_management_db;



CREATE TABLE Member_Category (
    Member_Type_ID VARCHAR(20) NOT NULL,
    Type_Name VARCHAR(20) NOT NULL,
    Borrowing_Limit INT NOT NULL DEFAULT 3,
    Loan_Period INT NOT NULL DEFAULT 14,
    CONSTRAINT PK_Member_Category PRIMARY KEY (Member_Type_ID),
    CONSTRAINT unique_Membr_Category_TypeName UNIQUE(Type_Name), 
    CONSTRAINT check_MemberCategoryLimit CHECK (Borrowing_Limit BETWEEN 1 AND  20 AND Loan_Period BETWEEN 1 AND 90) 
)ENGINE=InnoDB;

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
    CONSTRAINT FK_MemberTypeID FOREIGN KEY (Member_Type_ID) REFERENCES Member_Category (Member_Type_ID)
    ON DELETE RESTRICT ON UPDATE CASCADE, -- không cho xóa cột Member_Type_ID ở bản cha khi có bản con tham chiếu đến và có thể update thay đổi được
    CONSTRAINT check_Emailformat CHECK (Email LIKE '%_@__%.__%'),
    CONSTRAINT check_Member_AccountStatus CHECK (Account_Status IN('Acitve','Suspended','Expired','Locked'))

)ENGINE=InnoDB;

