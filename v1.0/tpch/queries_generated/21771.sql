WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS hierarchy_level
    FROM supplier
    WHERE s_acctbal IS NOT NULL AND s_acctbal > 5000.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.hierarchy_level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_suppkey = (
        SELECT ps_suppkey
        FROM partsupp ps
        WHERE ps.ps_partkey IN (
            SELECT p.p_partkey 
            FROM part p 
            WHERE p.p_retailprice BETWEEN 50 AND 150
        ) 
        ORDER BY ps.ps_availqty DESC 
        LIMIT 1
    )
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE NULL END) AS total_returns,
    AVG(s.s_acctbal) AS avg_supplier_acctbal,
    MAX(s.s_acctbal) FILTER (WHERE s.s_acctbal > 10000) AS max_high_acctbal,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
WHERE 
    o.o_orderdate BETWEEN '2023-01-01' AND CURRENT_DATE
AND 
    (l.l_discount IS NULL OR l.l_discount < 0.1)
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10 
    AND AVG(l.l_quantity) > (SELECT AVG(l_sub.l_quantity) FROM lineitem l_sub WHERE l_sub.l_shipmode = 'AIR')
ORDER BY 
    total_revenue DESC NULLS LAST;
