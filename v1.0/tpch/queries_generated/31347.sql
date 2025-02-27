WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000.00
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal BETWEEN 500.00 AND 1000.00
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent,
           AVG(o.o_totalprice) AS avg_order_value,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
),
HighValueParts AS (
    SELECT p.p_partkey, p.p_name, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > 50.00
    GROUP BY p.p_partkey, p.p_name
    HAVING AVG(ps.ps_supplycost) < 20.00
)
SELECT 
    c.c_name AS CustomerName,
    co.order_count AS OrdersCount,
    co.total_spent AS TotalSpent,
    p.p_name AS PartName,
    hvp.avg_supply_cost AS AverageSupplyCost,
    s.s_name AS SupplierName,
    s.s_acctbal AS SupplierAccountBalance
FROM CustomerOrderSummary co
FULL OUTER JOIN HighValueParts hvp ON co.order_count > 0
JOIN supplier s ON s.s_nationkey = co.c_custkey
LEFT JOIN part p ON p.p_partkey = hvp.p_partkey
WHERE co.rank <= 5 OR hvp.avg_supply_cost IS NOT NULL
ORDER BY TotalSpent DESC NULLS LAST, AverageSupplyCost ASC;
