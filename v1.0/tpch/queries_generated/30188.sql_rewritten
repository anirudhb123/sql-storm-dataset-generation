WITH RECURSIVE order_hierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, 
           1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, oh.o_custkey, o.o_orderdate, o.o_totalprice,
           oh.level + 1
    FROM orders o
    JOIN order_hierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > (SELECT MAX(o2.o_orderdate) FROM orders o2 WHERE o2.o_orderkey = oh.o_orderkey)
)

SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(COALESCE(l.l_extendedprice * (1 - l.l_discount), 0)) AS total_revenue,
    AVG(CASE 
        WHEN c.c_acctbal IS NULL THEN 0
        ELSE c.c_acctbal
    END) AS avg_acctbal,
    MAX(l.l_shipdate) AS last_shipdate,
    STRING_AGG(DISTINCT p.p_name, ', ') AS popular_parts
FROM 
    customer c
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    o.o_orderdate > cast('1998-10-01' as date) - INTERVAL '1 year'
    AND (l.l_returnflag IS NULL OR l.l_returnflag <> 'R')
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_revenue DESC,
    customer_count DESC;