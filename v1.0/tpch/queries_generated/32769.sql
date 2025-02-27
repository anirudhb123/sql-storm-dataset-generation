WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus, 1 AS order_level
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus, oh.order_level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS return_revenue,
    AVG(o.o_totalprice) AS average_order_value,
    MAX(l.l_shipdate) AS last_ship_date,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', p.p_mfgr, ')'), '; ') AS part_names,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice) DESC) AS nation_rank
FROM 
    customer c
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    o.o_orderstatus IN ('F', 'O') AND
    (l.l_discount BETWEEN 0.05 AND 0.2 OR l.l_tax > 0.1) AND
    n.n_regionkey IS NOT NULL
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 50
ORDER BY 
    return_revenue DESC;
