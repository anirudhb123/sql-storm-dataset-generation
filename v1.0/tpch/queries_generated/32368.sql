WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        0 AS level
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        oh.level + 1
    FROM 
        orders o
    JOIN 
        OrderHierarchy oh ON o.o_orderkey = (SELECT MIN(o2.o_orderkey) FROM orders o2 WHERE o2.o_custkey = oh.o_orderkey)
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        oh.level < 10  -- Limit the levels to avoid infinite loops
)

SELECT 
    rh.r_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(o.o_totalprice) AS total_revenue,
    AVG(c.c_acctbal) AS avg_account_balance,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
    MAX(l.l_shipdate) AS last_ship_date,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM 
    OrderHierarchy oh
JOIN 
    lineitem l ON oh.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region rh ON n.n_regionkey = rh.r_regionkey
JOIN 
    part p ON p.p_partkey = l.l_partkey
LEFT JOIN
    customer c ON oh.o_orderkey = c.c_custkey  -- Including customers with NULL values
WHERE 
    l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'  
    AND (c.c_acctbal IS NOT NULL AND c.c_acctbal > 0)
GROUP BY 
    rh.r_name
ORDER BY 
    total_revenue DESC
FETCH FIRST 10 ROWS ONLY;
