-- Queries the database must answer
-- 1 The copies of a title currently available. 
-- 2 The loans of one member that are overdue today.
-- 3 The ten most borrowed titles this year.
-- 4 Members who have borrowed every title by a given author.
-- 5 The total fines outstanding per member category

-- Create Index for query optimization 

-- Indexes for Circulation & Fine queries (query 2 ,3 ,5)
CREATE INDEX index_loanTransaction_member_due    ON Loan_Transaction (Member_ID, Due_Date);

CREATE INDEX idx_loan_detail_return_date  ON Loan_Detail (Return_Date);

CREATE INDEX idx_loantransaction_borrow_date      ON Loan_Transaction (Borrow_Date);

CREATE INDEX idx_loan_detail_payment_fine ON Loan_Detail (Payment_Status, Fine_Amount);

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
