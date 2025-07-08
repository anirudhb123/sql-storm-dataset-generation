
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 10000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey + 1
    WHERE s.s_acctbal IS NOT NULL
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost, 
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           CASE 
               WHEN o.o_totalprice > 5000 THEN 'High'
               WHEN o.o_totalprice BETWEEN 1000 AND 5000 THEN 'Medium'
               ELSE 'Low'
           END AS order_value_category
    FROM orders o
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(l.l_extendedprice) AS total_sales,
    AVG(l.l_discount) AS avg_discount,
    LISTAGG(DISTINCT CONCAT(pt.p_name, ' (', COALESCE(p_avail.avail_qty, 0), ')'), ', ') WITHIN GROUP (ORDER BY pt.p_name) AS parts_info,
    sh.level AS supplier_level
FROM 
    region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN orders o ON o.o_custkey = c.c_custkey
LEFT JOIN lineitem l ON l.l_orderkey = o.o_orderkey
LEFT JOIN PartSupplierInfo pt ON l.l_partkey = pt.p_partkey AND pt.rank = 1
LEFT JOIN (
    SELECT ps_partkey, SUM(ps_availqty) AS avail_qty
    FROM partsupp
    GROUP BY ps_partkey
) p_avail ON pt.p_partkey = p_avail.ps_partkey
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = l.l_suppkey
WHERE 
    l.l_shipdate > '1996-01-01' 
    AND (l.l_discount IS NULL OR l.l_discount < 0.1)
GROUP BY 
    r.r_name, n.n_name, sh.level
ORDER BY 
    region_name, nation_name;
