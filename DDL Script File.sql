
--Create Database 
USE master
GO

DECLARE @data_path NVARCHAR(256)
SET @data_path =
(
    SELECT SUBSTRING(physical_name, 1, CHARINDEX(N'master.mdf', LOWER(physical_name)) - 1)
    FROM master.sys.master_files
    WHERE database_id = 1 AND file_id = 1
)

EXECUTE ('CREATE DATABASE SweetsBakeryStoreDB 
    ON PRIMARY 
    (NAME = SweetsBakeryStoreDB_data, FILENAME = ''' + @data_path + 'SweetsBakeryStoreDB_data.mdf'', SIZE = 20MB, MAXSIZE = UNLIMITED, FILEGROWTH = 2MB )
    LOG ON 
    (NAME = SweetsBakeryStoreDB_log, FILENAME = ''' + @data_path + 'SweetsBakeryStoreDB_log.ldf'', SIZE = 10MB, MAXSIZE = 100MB, FILEGROWTH = 1MB)')
GO

--Drop Database SweetsBakeryStoreDB
--Go

USE SweetsBakeryStoreDB
GO

 
 
CREATE TABLE Categories
(
    CategoryID INT PRIMARY KEY IDENTITY(1,1),
    CategoryName VARCHAR(100) NOT NULL
)
GO

CREATE TABLE SubCategories
(
    SubCategoryID INT PRIMARY KEY IDENTITY(1,1),
    CategoryID INT FOREIGN KEY REFERENCES Categories(CategoryID),
    SubCategoryName VARCHAR(100) NOT NULL
)
GO

 CREATE TABLE Suppliers
(
    SupplierID INT PRIMARY KEY IDENTITY(1,1),
    SupplierName VARCHAR(100) NOT NULL UNIQUE,
    ContactNumber VARCHAR(20),
    Address VARCHAR(200)
)
GO

 CREATE TABLE Products 
(
    ProductID INT PRIMARY KEY IDENTITY(1,1),
    SubCategoryID INT FOREIGN KEY REFERENCES SubCategories(SubCategoryID),
    SupplierID INT FOREIGN KEY REFERENCES Suppliers(SupplierID),
    ProductName VARCHAR(100) NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    ExpiryDate DATE,
    IsActive BIT DEFAULT 1,
    ProductImage VARBINARY(MAX)
)
GO

ALTER TABLE Products
ALTER COLUMN ProductName VARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS;
GO

CREATE TABLE ProductVarients
(
    VarietyID INT PRIMARY KEY IDENTITY(1,1),
    ProductID INT FOREIGN KEY REFERENCES Products(ProductID),
    VarietyName VARCHAR(50) NOT NULL,
    PriceModifier DECIMAL(5,2) DEFAULT 0.00
)
GO

 CREATE TABLE GRN
(
    GRN_ID INT PRIMARY KEY IDENTITY(1,1),
    SupplierID INT FOREIGN KEY REFERENCES Suppliers(SupplierID),
    GRNDate DATE NOT NULL,
    Notes VARCHAR(200)
)
GO

CREATE TABLE GRNDetails
(
    GRNDetailID INT PRIMARY KEY IDENTITY(1,1),
    GRN_ID INT FOREIGN KEY REFERENCES GRN(GRN_ID),
    ProductID INT FOREIGN KEY REFERENCES Products(ProductID),
    Quantity INT NOT NULL,
    UnitCost DECIMAL(10,2)
)
GO

CREATE TABLE Customers
(
    CustomerID INT PRIMARY KEY IDENTITY(1,1),
    CustomerName VARCHAR(100) NOT NULL,
    Phone VARCHAR(20),
    Address VARCHAR(200)
)
GO

CREATE TABLE CustomerLog
(
    LogID INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT FOREIGN KEY REFERENCES Customers(CustomerID),
    FirstOrderDate DATE
)
GO

CREATE TABLE CustomerRequirements
(
    RequirementID INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT FOREIGN KEY REFERENCES Customers(CustomerID),
    ProductName VARCHAR(100) NOT NULL,
    RequestDate DATE,
    Status VARCHAR(20) DEFAULT 'Pending',
    ExtraNotes VARCHAR(200) SPARSE NULL
)
GO

CREATE TABLE Orders
(
    OrderID INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT FOREIGN KEY REFERENCES Customers(CustomerID),
    OrderDate DATE NOT NULL,
    TotalAmount DECIMAL(10,2),
    IsPaid BIT DEFAULT 0
)
GO

CREATE TABLE OrderDetails
(
    OrderDetailID INT PRIMARY KEY IDENTITY(1,1),
    OrderID INT FOREIGN KEY REFERENCES Orders(OrderID),
    VarietyID INT FOREIGN KEY REFERENCES ProductVarients(VarietyID),
    Quantity INT NOT NULL,
    LineTotal DECIMAL(10,2)
)
GO

CREATE TABLE Payments 
(
    PaymentID INT PRIMARY KEY IDENTITY(1,1),
    OrderID INT FOREIGN KEY REFERENCES Orders(OrderID),
    PaidAmount DECIMAL(10,2),
    PaymentDate DATE,
    PaymentMethod VARCHAR(50)
)
GO

CREATE TABLE ProductsMissing
(
    MissingID INT PRIMARY KEY IDENTITY(1,1),
    ProductID INT FOREIGN KEY REFERENCES Products(ProductID),
    ReportDate DATE,
    Reason VARCHAR(100),
    DamageType VARCHAR(50)
)
GO

 
-- Scalar Function
CREATE FUNCTION fn_GetCustomerOrderCount (@CustomerID INT)
RETURNS INT
AS
BEGIN
    DECLARE @Count INT;
    SELECT @Count = COUNT(*) FROM Orders WHERE CustomerID = @CustomerID;
    RETURN @Count;
END
GO

--Table-Valued Function
CREATE FUNCTION fn_GetOrdersByCustomer (@CustomerID INT)
RETURNS TABLE
AS
RETURN
(
    SELECT OrderID, OrderDate, TotalAmount, IsPaid
    FROM Orders
    WHERE CustomerID = @CustomerID
)
GO

-- Multi-Statement Table Function
CREATE FUNCTION fn_GetCustomerPaymentSummary (@CustomerID INT)
RETURNS @Summary TABLE
(
    OrderID INT,
    PaidAmount DECIMAL(10,2),
    PaymentDate DATE
)
AS
BEGIN
    INSERT INTO @Summary
    SELECT p.OrderID, p.PaidAmount, p.PaymentDate
    FROM Payments p
    JOIN Orders o ON p.OrderID = o.OrderID
    WHERE o.CustomerID = @CustomerID;

    RETURN
END
GO
 
--Views

CREATE VIEW vw_DamagedProducts AS
SELECT 
    p.ProductID,
    p.ProductName,
    pm.ReportDate,
    pm.Reason,
    pm.DamageType
FROM ProductsMissing pm
JOIN Products p ON pm.ProductID = p.ProductID
GO


CREATE VIEW vw_ActiveProducts
WITH SCHEMABINDING
AS
SELECT ProductID, ProductName, UnitPrice
FROM dbo.Products
WHERE IsActive = 1
GO


CREATE VIEW vw_CustomerDemand AS
SELECT 
    cr.RequirementID,
    c.CustomerName,
    cr.ProductName,
    cr.RequestDate,
    cr.Status
FROM CustomerRequirements cr
JOIN Customers c ON cr.CustomerID = c.CustomerID;
GO

--Trigger 

CREATE TRIGGER trg_AutoLogCustomer
ON Orders
AFTER INSERT
AS
BEGIN
    INSERT INTO CustomerLog (CustomerID, FirstOrderDate)
    SELECT CustomerID, OrderDate
    FROM inserted
    WHERE NOT EXISTS
    (
        SELECT 1 FROM CustomerLog WHERE CustomerID = inserted.CustomerID
    )
END
GO


--Store Procedure
--Add Order

CREATE PROCEDURE sp_AddOrder
    @CustomerID INT,
    @OrderDate DATE,
    @TotalAmount DECIMAL(10,2),
    @IsPaid BIT
AS
BEGIN
    INSERT INTO Orders (CustomerID, OrderDate, TotalAmount, IsPaid)
    VALUES (@CustomerID, @OrderDate, @TotalAmount, @IsPaid)
END
GO


--Update Order
CREATE PROCEDURE sp_UpdateOrder
    @OrderID INT,
    @TotalAmount DECIMAL(10,2),
    @IsPaid BIT
AS
BEGIN
    UPDATE Orders
    SET TotalAmount = @TotalAmount,
        IsPaid = @IsPaid
    WHERE OrderID = @OrderID;
END
GO

--Delete Order

CREATE PROCEDURE sp_DeleteOrder
    @OrderID INT
AS
BEGIN
    DELETE FROM OrderDetails WHERE OrderID = @OrderID
    DELETE FROM Payments WHERE OrderID = @OrderID
    DELETE FROM Orders WHERE OrderID = @OrderID
END
GO


--Add Payment
CREATE PROCEDURE sp_AddPayment
    @OrderID INT,
    @PaidAmount DECIMAL(10,2),
    @PaymentDate DATE,
    @PaymentMethod VARCHAR(50)
AS
BEGIN
    INSERT INTO Payments (OrderID, PaidAmount, PaymentDate, PaymentMethod)
    VALUES (@OrderID, @PaidAmount, @PaymentDate, @PaymentMethod)
END
GO

--Stock Check

CREATE PROCEDURE sp_CheckStock
    @ProductID INT
AS
BEGIN
    DECLARE @Stock INT
    SELECT @Stock = SUM(Quantity) FROM GRNDetails WHERE ProductID = @ProductID;

    IF @Stock < 10
        PRINT 'Low Stock'
    ELSE
        PRINT 'Stock OK'
END
GO

--Index

CREATE INDEX IX_Orders_OrderDate ON Orders(OrderDate);
GO

--Ansi nulls
SET ANSI_NULLS ON
SET NOCOUNT ON
SET DATEFORMAT dmy
GO
