WITH RECURSIVE SuppliersHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_acctbal, 
           1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_acctbal, 
           sh.level + 1
    FROM supplier s
    JOIN SuppliersHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
TopParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_type, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_type
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
RankedSuppliers AS (
    SELECT s.s_supplierkey, s.s_name, s.s_nationkey, 
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS accts_rank
    FROM supplier s
)
SELECT sh.s_name AS Supplier_Name, 
       pt.p_name AS Part_Name, 
       pt.revenue,
       r.r_name AS Region_Name,
       COUNT(DISTINCT c.c_custkey) AS Customer_Count,
       SUM(o.o_totalprice) AS Total_Sales
FROM SuppliersHierarchy sh
JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
JOIN TopParts pt ON ps.ps_partkey = pt.p_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN orders o ON o.o_custkey = c.c_custkey
WHERE sh.level <= 3
  AND r.r_name IS NOT NULL
GROUP BY sh.s_name, pt.p_name, pt.revenue, r.r_name
HAVING SUM(o.o_totalprice) > 5000
ORDER BY pt.revenue DESC, Customer_Count ASC;
