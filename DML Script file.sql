 
-- Categories
INSERT INTO Categories (CategoryName)
VALUES
    ('Sweets'), ('Fast Food'), ('Drinks')
GO

-- SubCategories
INSERT INTO SubCategories (CategoryID, SubCategoryName)
VALUES 
    (1, 'Milk-based'), 
    (1, 'Dry Sweets'), 
    (2, 'Snacks'), 
    (3, 'Juice')
GO

-- Suppliers
INSERT INTO Suppliers (SupplierName, ContactNumber, Address)
VALUES 
    ('Golden Dairy Ltd.', '01711112222', 'Dhaka'),
    ('SweetMart Traders', '01888883333', 'Chattogram'),
    ('Fresh Agro', '01999994444', 'Sylhet')
GO

-- Products
INSERT INTO Products (SubCategoryID, SupplierID, ProductName, UnitPrice, ExpiryDate)
VALUES 
    (1, 1, 'Milk Sandesh', 15.00, '2025-09-30'),
    (2, 2, 'Dry Chamcham', 12.00, '2025-10-15'),
    (3, 2, 'Chicken Roll', 25.00, '2025-09-12'),
    (4, 3, 'Mango Juice', 18.00, '2025-09-20')
GO

-- ProductVarients
INSERT INTO ProductVarients (ProductID, VarietyName, PriceModifier)
VALUES 
    (1, 'Small', 0.00), 
    (1, 'Large', 5.00), 
    (3, 'Regular', 0.00), 
    (3, 'Spicy', 2.00)
GO

-- GRN
INSERT INTO GRN (SupplierID, GRNDate, Notes)
VALUES 
    (1, '2025-09-01', 'Milk sweets batch'), 
    (2, '2025-09-05', 'Dry sweets delivery')
GO

-- GRNDetails
INSERT INTO GRNDetails (GRN_ID, ProductID, Quantity, UnitCost)
VALUES 
    (1, 1, 100, 10.00), 
    (2, 2, 150, 8.00)
GO

-- Customers
INSERT INTO Customers (CustomerName, Phone, Address)
VALUES 
    ('Rahim Uddin', '01712345678', 'Agrabad'),
    ('Nasima Akter', '01823456789', 'Panchlaish'),
    ('Tanvir Hasan', '01934567890', 'Halishahar')
GO

-- CustomerRequirements
INSERT INTO CustomerRequirements (CustomerID, ProductName, RequestDate, Status)
VALUES 
    (1, 'Sugar-free Sandesh', '2025-09-05', 'Pending'),
    (3, 'Spicy Chicken Roll', '2025-09-06', 'Fulfilled')
GO

-- ProductsMissing
INSERT INTO ProductsMissing (ProductID, ReportDate, Reason, DamageType)
VALUES 
    (2, '2025-09-10', 'Crushed during delivery', 'Broken'),
    (4, '2025-09-11', 'Expired stock', 'Expired')
GO

 
-- Add Order
EXEC sp_AddOrder 
    @CustomerID = 1,
    @OrderDate = '2025-09-12',
    @TotalAmount = 80.00,
    @IsPaid = 1
GO

-- Add Payment
EXEC sp_AddPayment 
    @OrderID = 1,
    @PaidAmount = 80.00,
    @PaymentDate = '2025-09-12',
    @PaymentMethod = 'Cash'
GO

-- Update Order
EXEC sp_UpdateOrder 
    @OrderID = 1,
    @TotalAmount = 85.00,
    @IsPaid = 1
GO

-- Delete Order  
EXEC sp_DeleteOrder 
    @OrderID = 2
GO

--Views & Function Queries

-- Damaged Products View
SELECT * FROM vw_DamagedProducts

-- Customer Demand View
SELECT * FROM vw_CustomerDemand

-- Scalar Function
SELECT dbo.fn_GetCustomerOrderCount(1) AS TotalOrders

-- Inline Table-Valued Function
SELECT * FROM fn_GetOrdersByCustomer(1)

-- Multi-Statement Table-Valued Function
SELECT * FROM fn_GetCustomerPaymentSummary(1)
GO

 
-- TOP & ORDER BY
SELECT TOP 5 VarietyID, SUM(Quantity) AS TotalSold
FROM OrderDetails
GROUP BY VarietyID
ORDER BY TotalSold DESC
GO

-- GROUP BY, HAVING, ROLLUP
SELECT ProductID, SUM(Quantity) AS TotalSold
FROM GRNDetails
GROUP BY ROLLUP(ProductID)
HAVING SUM(Quantity) > 50
GO

-- OUTER JOIN
SELECT p.ProductName, g.Quantity
FROM Products p
LEFT OUTER JOIN GRNDetails g ON p.ProductID = g.ProductID
GO

-- CROSS JOIN
SELECT p.ProductName, v.VarietyName
FROM Products p
CROSS JOIN ProductVarients v
GO

-- DISTINCT, OFFSET, FETCH
SELECT DISTINCT CustomerName FROM Customers

SELECT OrderID, OrderDate
FROM Orders
ORDER BY OrderDate
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY
GO

-- CASE, BETWEEN, LIKE, IS NULL
SELECT ProductName,
    CASE 
        WHEN ExpiryDate BETWEEN GETDATE() AND DATEADD(DAY, 7, GETDATE()) THEN 'Expiring Soon'
        WHEN ExpiryDate IS NULL THEN 'No Expiry'
        ELSE 'Valid'
    END AS Status
FROM Products
WHERE ProductName LIKE '%Roll%'
GO

-- ANY, ALL
SELECT OrderID 
FROM Payments
WHERE PaidAmount < ANY (SELECT PaidAmount FROM Payments WHERE PaymentMethod = 'Card')

-- UNION ALL
SELECT GRN_ID AS RefID, GRNDate AS Date, 'GRN' AS Type FROM GRN
UNION ALL
SELECT OrderID, OrderDate, 'Order' FROM Orders

-- OVER, AVG, MAX, MIN
SELECT 
    CustomerID,
    PaidAmount,
    AVG(PaidAmount) OVER (PARTITION BY CustomerID) AS AvgPaid,
    MAX(PaidAmount) OVER (PARTITION BY CustomerID) AS MaxPaid
FROM Payments
GO
