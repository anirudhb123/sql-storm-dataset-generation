
WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        1 AS level
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        oh.level + 1
    FROM 
        orders o
    JOIN 
        OrderHierarchy oh ON o.o_custkey = oh.o_orderkey
)
SELECT 
    p.p_name,
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(s.s_acctbal) AS avg_supplier_balance,
    RANK() OVER (PARTITION BY p.p_type ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank,
    STRING_AGG(DISTINCT c.c_comment, ', ') AS customer_comments
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
INNER JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_retailprice > 50.00 
    AND (s.s_acctbal IS NULL OR s.s_acctbal < 1000.00)
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, p.p_type
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 5
ORDER BY 
    total_revenue DESC;
