WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS Level
    FROM orders
    WHERE o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.Level + 1
    FROM orders o
    INNER JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
),
HighestSpenders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > (SELECT AVG(o2.o_totalprice) FROM orders o2)
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS SupplierRank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT s.s_nationkey, s.s_name, s.TotalSupplyCost
    FROM RankedSuppliers s
    WHERE s.SupplierRank <= 5
),
FinalReport AS (
    SELECT oh.o_orderkey, oh.o_orderdate, oh.o_totalprice, c.c_name AS CustomerName,
           COALESCE(ts.s_name, 'Unknown') AS TopSupplier
    FROM OrderHierarchy oh
    LEFT JOIN HighestSpenders c ON oh.o_custkey = c.c_custkey
    LEFT JOIN TopSuppliers ts ON ts.s_nationkey = (SELECT n.n_nationkey 
                                                    FROM nation n 
                                                    JOIN customer cu ON cu.c_nationkey = n.n_nationkey 
                                                    WHERE cu.c_custkey = c.c_custkey
                                                    LIMIT 1)
)
SELECT COUNT(*) AS OrderCount, 
       AVG(o_totalprice) AS AvgOrderPrice,
       MIN(o_orderdate) AS FirstOrderDate,
       MAX(o_orderdate) AS LastOrderDate
FROM FinalReport
GROUP BY TopSupplier
ORDER BY OrderCount DESC, AvgOrderPrice DESC;
