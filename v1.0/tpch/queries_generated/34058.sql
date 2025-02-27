WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
Quantities AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_availability
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_totalprice > 10000
),
JoinedData AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           r.r_name AS region_name, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
           COALESCE(SUM(l.l_quantity), 0) AS total_quantity
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    FULL OUTER JOIN supplier s ON s.s_suppkey = l.l_suppkey
    LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE p.p_size IN (SELECT DISTINCT p1.p_size FROM part p1 WHERE p1.p_retailprice > 500)
    GROUP BY p.p_partkey, r.r_name, p.p_name, p.p_retailprice
)
SELECT j.p_partkey, j.p_name, j.total_quantity, j.revenue, j.region_name,
       CASE 
           WHEN j.total_quantity IS NULL THEN 'No Sales'
           WHEN j.total_quantity > 100 THEN 'High Sale'
           ELSE 'Low Sale'
       END AS sale_status,
       sh.s_name AS supplier_name,
       CASE 
           WHEN h.o_orderkey IS NOT NULL THEN 'High Value'
           ELSE 'Regular'
       END AS order_status
FROM JoinedData j
LEFT JOIN HighValueOrders h ON j.p_partkey = h.o_orderkey
LEFT JOIN SupplierHierarchy sh ON j.region_name = (SELECT r_name FROM region WHERE r_regionkey = sh.s_nationkey)
WHERE j.revenue > (SELECT AVG(revenue) FROM JoinedData)
ORDER BY j.revenue DESC
LIMIT 100;
