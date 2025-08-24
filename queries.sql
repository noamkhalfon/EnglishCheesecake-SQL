-- Query 1: Ranking customers by total order value
SELECT c.[Email Address], 
       Full_Name = c.[First Name] + ' ' + c.[Last Name],
       SUM(CO.Units * p.Price) AS TotalOrderValue,
       RANK() OVER (ORDER BY SUM(CO.Units * p.Price) DESC) AS CustomerRank,
       NTILE(4) OVER (ORDER BY SUM(CO.Units* p.Price) DESC) AS CustomerQuartile
FROM Customers AS c 
JOIN CreditCards AS cc ON c.[Email Address] = cc.[Email address]
JOIN Orders AS o ON cc.[CC number] = o.[CC number]
JOIN CONTAIN AS co ON o.OrderID = co.OrderID
JOIN Products AS p ON co.ProductID = p.ProductID
GROUP BY c.[Email address], c.[First name], c.[Last name]
ORDER BY CustomerRank;


-- Query 2: High-rated product spending ratio
WITH ProductRatings AS (
    SELECT ProductID,
           AVG(CAST(Rating AS FLOAT)) AS AvgRating
    FROM REVIEWS
    GROUP BY ProductID
),
HighRatedOrders AS (
    SELECT C.[Email Address],
           SUM(CO.Units * P.Price) AS TotalHighRatedSpending
    FROM CUSTOMERS AS C
    JOIN CREDITCARDS AS CC ON C.[Email Address] = CC.[Email Address]
    JOIN ORDERS AS O ON CC.[CC Number] = O.[CC Number]
    JOIN CONTAIN AS CO ON O.OrderID = CO.OrderID 
    JOIN PRODUCTS AS P ON CO.ProductID = P.ProductID 
    JOIN ProductRatings AS PR ON P.ProductID = PR.ProductID
    WHERE PR.AvgRating > 4.5
    GROUP BY C.[Email Address]
),
AllOrders AS (
    SELECT C.[Email Address],
           SUM(CO.Units * P.Price) AS TotalSpending
    FROM CUSTOMERS AS C
    JOIN CREDITCARDS AS CC ON C.[Email Address] = CC.[Email Address]
    JOIN ORDERS AS O ON CC.[CC number] = O.[CC number]
    JOIN CONTAIN AS CO ON O.ORDERID = CO.ORDERID
    JOIN PRODUCTS AS P ON CO.PRODUCTID = P.PRODUCTID
    GROUP BY C.[Email Address]
)
SELECT A.[Email Address],
       A.TotalSpending,
       ISNULL(H.TotalHighRatedSpending, 0) AS HighRatedSpending,
       CAST(ISNULL(H.TotalHighRatedSpending, 0) AS FLOAT) / NULLIF(A.TotalSpending, 0) AS HighRatedPurchaseRatio,
       RANK() OVER (ORDER BY ISNULL(H.TotalHighRatedSpending, 0) DESC) AS HighRatedCustomerRank
FROM AllOrders AS A
LEFT JOIN HighRatedOrders AS H ON A.[Email Address] = H.[Email Address];
