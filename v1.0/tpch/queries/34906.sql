WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON ps.ps_suppkey = sh.s_suppkey
    JOIN supplier s ON ps.ps_partkey = s.s_suppkey
)

SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice ELSE NULL END) AS avg_filled_order_price,
    STRING_AGG(DISTINCT CONCAT('Supplier: ', sh.s_name, ' (Level: ', sh.level, ')'), '; ') AS supplier_hierarchy
FROM 
    nation n
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    supplier_hierarchy sh ON sh.s_nationkey = n.n_nationkey
WHERE 
    l.l_shipdate >= '1997-01-01' 
    AND (o.o_orderpriority = 'HIGH' OR o.o_orderpriority IS NULL)
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 10
ORDER BY 
    total_revenue DESC
LIMIT 5;