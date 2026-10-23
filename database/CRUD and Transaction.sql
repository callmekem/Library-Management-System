-- CRUD for Member

INSERT INTO Member (Member_ID, Member_Type_ID, Full_Name, Email, Identity_Card, Membership_Expiry_Date, Account_Status)
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