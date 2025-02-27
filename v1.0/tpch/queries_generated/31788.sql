WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON ps.ps_suppkey = sh.s_suppkey
    JOIN supplier s ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 50
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(CASE WHEN o.o_orderstatus = 'O' THEN o.o_totalprice ELSE 0 END) AS total_open_orders,
    ROUND(AVG(l.l_extendedprice * (1 - l.l_discount)), 2) AS avg_price_after_discount,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice) DESC) AS price_rank
FROM 
    region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN orders o ON o.o_custkey = c.c_custkey
LEFT JOIN lineitem l ON l.l_orderkey = o.o_orderkey
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = c.c_nationkey
WHERE 
    l.l_shipdate >= DATE '2023-01-01'
    AND (l.l_returnflag IS NULL OR l.l_returnflag = 'N')
    AND (sh.level IS NULL OR sh.level <= 3)
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_open_orders DESC, r.r_name ASC;
