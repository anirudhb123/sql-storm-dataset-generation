WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS Level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT oh.o_orderkey, o.o_orderdate, o.o_totalprice, Level + 1
    FROM OrderHierarchy oh
    JOIN orders o ON o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_name LIKE 'Customer%')
    WHERE oh.o_orderkey = o.o_orderkey
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
PartSummary AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS Rank
    FROM part p
    WHERE p.p_size > 10 AND p.p_retailprice IS NOT NULL
),
CustomerOrders AS (
    SELECT c.c_name, COUNT(o.o_orderkey) AS OrderCount, SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2023-01-01' OR o.o_orderdate IS NULL
    GROUP BY c.c_name
)
SELECT 
    rh.o_orderkey,
    rh.o_orderdate,
    rh.o_totalprice,
    sd.s_name,
    ps.p_name,
    co.OrderCount,
    co.TotalSpent,
    COALESCE(CASE 
                WHEN co.TotalSpent > 1000 THEN 'High Value'
                WHEN co.TotalSpent BETWEEN 500 AND 1000 THEN 'Medium Value'
                ELSE 'Low Value' 
             END, 'No Orders') AS CustomerValue,
    COUNT(DISTINCT rh.Level) AS OrderLevelCount
FROM 
    OrderHierarchy rh
    LEFT JOIN SupplierDetails sd ON sd.TotalCost > 1000
    LEFT JOIN PartSummary ps ON ps.Rank <= 5
    LEFT JOIN CustomerOrders co ON co.c_name = (SELECT c.c_name FROM customer c WHERE c.c_custkey = rh.o_orderkey)
GROUP BY 
    rh.o_orderkey, rh.o_orderdate, rh.o_totalprice, sd.s_name, ps.p_name, co.OrderCount, co.TotalSpent
ORDER BY 
    rh.o_orderdate;
