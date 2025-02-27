WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS lvl
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)  -- Select suppliers with above average balance

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.lvl + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey  -- Self-join on nation key to form a hierarchy
)

SELECT n.n_name AS Nation,
       COUNT(DISTINCT c.c_custkey) AS Customer_Count,
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS Total_Sales,
       SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS Total_Returns,
       AVG(s.acctbal) AS Avg_Supplier_Balance,
       STRING_AGG(DISTINCT p.p_name, ', ') AS Part_Names
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = n.n_nationkey  -- Left join to include suppliers
WHERE o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
GROUP BY n.n_name
HAVING COUNT(DISTINCT c.c_custkey) > 10 
   AND Total_Sales > 50000
ORDER BY Total_Sales DESC
FETCH FIRST 10 ROWS ONLY;
