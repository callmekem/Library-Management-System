
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
