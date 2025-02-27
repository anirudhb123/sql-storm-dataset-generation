WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, s_comment, CAST(s_name AS VARCHAR(255)) AS full_name, 0 AS level
    FROM supplier
    WHERE s_suppkey = (SELECT MIN(s_suppkey) FROM supplier) -- Starting point
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, CONCAT(SH.full_name, ' -> ', s.s_name) AS full_name, level + 1
    FROM supplier s
    JOIN SupplierHierarchy SH ON SH.s_suppkey = s.s_suppkey -- Recursive join - adjust this join condition to simulate hierarchy
    WHERE SH.level < 5 -- limit the recursion depth
),
OrderInfo AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue 
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
),
NationRegion AS (
    SELECT n.n_nationkey, n.n_name, r.r_name, COUNT(s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name, r.r_name
)
SELECT 
    p.p_name, 
    p.p_brand, 
    SUM(ps.ps_availqty) AS total_available_qty, 
    COALESCE(o.total_revenue, 0) AS order_total_revenue, 
    NR.supplier_count, 
    SH.level
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN OrderInfo o ON p.p_partkey = (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey LIMIT 1) -- Subquery to find an arbitrary part for each order
LEFT JOIN NationRegion NR ON (p.p_type LIKE '%metal%' AND NR.supplier_count IS NOT NULL) 
LEFT JOIN SupplierHierarchy SH ON SH.s_suppkey = (SELECT MIN(s.s_suppkey) FROM supplier s WHERE s.s_acctbal > 50000)
GROUP BY p.p_name, p.p_brand, o.total_revenue, NR.supplier_count, SH.level
HAVING total_available_qty > 0 AND 
       (o.total_revenue IS NULL OR order_total_revenue > 1000) AND 
       p.p_container IS NOT NULL 
ORDER BY total_available_qty DESC, order_total_revenue DESC, SH.level
LIMIT 100;
