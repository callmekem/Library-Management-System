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