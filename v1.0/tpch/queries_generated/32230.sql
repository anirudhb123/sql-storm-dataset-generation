WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS level
    FROM orders
    WHERE o_orderdate >= '2023-01-01'
    
    UNION ALL
    
    SELECT o.orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
)
SELECT 
    c.c_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COUNT(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN l.l_orderkey END) AS return_count,
    CASE 
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000 THEN 'High Value'
        ELSE 'Low Value'
    END AS revenue_category
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    o.o_orderstatus = 'O' 
    AND s.s_acctbal IS NOT NULL 
    AND (l.l_shipdate BETWEEN '2023-01-01' AND '2023-10-31' OR l.l_shipdate IS NULL)
GROUP BY 
    c.c_name
HAVING 
    total_revenue > 5000
ORDER BY 
    total_revenue DESC
LIMIT 10
UNION
SELECT 
    'Total' AS c_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)),
    COUNT(DISTINCT o.o_orderkey),
    COUNT(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN l.l_orderkey END),
    NULL
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
WHERE 
    o.o_orderstatus = 'O'
    AND s.s_acctbal IS NOT NULL
    AND (l.l_shipdate BETWEEN '2023-01-01' AND '2023-10-31' OR l.l_shipdate IS NULL);
