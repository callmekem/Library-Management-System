CREATE TABLE Category (
    Category_ID VARCHAR(50) PRIMARY KEY,
    Category_Name VARCHAR(100) NOT NULL UNIQUE,
    Description TEXT
);

CREATE TABLE Publisher (
    Publisher_ID VARCHAR(50) PRIMARY KEY,
    Publisher_Name VARCHAR(150) NOT NULL UNIQUE,
    Address VARCHAR(255),
    Contact_Email VARCHAR(100)
);

CREATE TABLE Author (
    Author_ID VARCHAR(50) PRIMARY KEY,
    Author_Name VARCHAR(150) NOT NULL,
    Biography TEXT
);

CREATE TABLE Book (
    Book_ID VARCHAR(50) PRIMARY KEY,
    Category_ID VARCHAR(50),
    Publisher_ID VARCHAR(50),
    ISBN VARCHAR(50) NOT NULL UNIQUE,
    Title VARCHAR(255) NOT NULL,
    Publication_Year INT CHECK (Publication_Year > 0),
    FOREIGN KEY (Category_ID) REFERENCES Category(Category_ID) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (Publisher_ID) REFERENCES Publisher(Publisher_ID) ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE TABLE Book_Author (
    Book_ID VARCHAR(50),
    Author_ID VARCHAR(50),
    Author_Order INT CHECK (Author_Order >= 1),
    PRIMARY KEY (Book_ID, Author_ID),
    UNIQUE (Book_ID, Author_Order),
    FOREIGN KEY (Book_ID) REFERENCES Book(Book_ID) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (Author_ID) REFERENCES Author(Author_ID) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Book_Copy (
    Book_ID VARCHAR(50),
    Copy_ID VARCHAR(50),
    Shelf_Location VARCHAR(100),
    Status VARCHAR(50) DEFAULT 'Available' CHECK (Status IN ('Available', 'Borrowed', 'Reserved', 'Damaged', 'Lost')),
    Condition_Notes TEXT,
    PRIMARY KEY (Book_ID, Copy_ID),
    FOREIGN KEY (Book_ID) REFERENCES Book(Book_ID) ON DELETE CASCADE ON UPDATE CASCADE
);

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
('AUTH15', 'George Orwell', 'English novelist, essayist, and critic.');

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

INSERT INTO Book_Copy (Book_ID, Copy_ID, Shelf_Location, Status, Condition_Notes) VALUES
('B01', 'C01', 'Shelf A - Row 1', 'Borrowed', 'Good condition'),
('B01', 'C02', 'Shelf A - Row 1', 'Available', 'New'),
('B02', 'C01', 'Shelf A - Row 2', 'Borrowed', 'Cover slightly bent'),
('B03', 'C01', 'Shelf B - Row 1', 'Reserved', 'Good condition'),
('B03', 'C02', 'Shelf B - Row 1', 'Available', 'Pages yellowed'),
('B04', 'C01', 'Shelf B - Row 2', 'Lost', 'Reported missing in 2025'),
('B05', 'C01', 'Shelf C - Row 1', 'Borrowed', 'Good condition'),
('B06', 'C01', 'Shelf C - Row 2', 'Damaged', 'Torn pages'),
('B07', 'C01', 'Shelf D - Row 1', 'Available', 'New'),
('B08', 'C01', 'Shelf D - Row 2', 'Available', 'Good condition'),
('B09', 'C01', 'Shelf E - Row 1', 'Reserved', 'Good condition'),
('B10', 'C01', 'Shelf E - Row 2', 'Borrowed', 'Cover damaged'),
('B11', 'C01', 'Shelf F - Row 1', 'Available', 'Good condition'),
('B12', 'C01', 'Shelf F - Row 2', 'Available', 'New'),
('B14', 'C01', 'Shelf G - Row 1', 'Available', 'Brand New - Never Borrowed'),
('B15', 'C01', 'Shelf G - Row 2', 'Available', 'Brand New - Never Borrowed');


