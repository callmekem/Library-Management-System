
USE library_management_db;
SET @old_safe_updates = @@SQL_SAFE_UPDATES;
SET SQL_SAFE_UPDATES = 0;

UPDATE Book_Copy bc
SET bc.Status = 'Borrowed'
WHERE EXISTS (SELECT 1 FROM Loan_Detail ld
              WHERE ld.Book_ID = bc.Book_ID
                AND ld.Copy_ID = bc.Copy_ID
                AND ld.Return_Date IS NULL);

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

-- =====================================================================
-- PART 4. TRANSACTION 2 - Return a book + pay the fine, CANCELLED (ROLLBACK)
-- State BEFORE
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