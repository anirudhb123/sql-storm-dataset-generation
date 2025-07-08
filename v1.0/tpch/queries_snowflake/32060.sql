WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(o.o_totalprice) AS total_orders_value,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount,
    MAX(DATE_PART('year', l.l_shipdate)) AS max_ship_year,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) > 10 THEN 'High Order'
        ELSE 'Low Order'
    END AS order_status
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN customer c ON o.o_custkey = c.c_custkey
WHERE l.l_shipdate >= '1997-01-01' 
    AND l.l_returnflag IS NULL
    AND (p.p_type LIKE '%COMPONENT%' OR p.p_type LIKE '%PART%')
GROUP BY r.r_name, s.s_name
ORDER BY r.r_name, total_orders_value DESC;