WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o_orderkey,
        o_custkey,
        o_orderstatus,
        o_orderdate,
        o_totalprice,
        1 AS level
    FROM orders
    WHERE o_orderdate >= '2023-01-01'

    UNION ALL

    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderstatus,
        o.o_orderdate,
        o.o_totalprice,
        oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
)

SELECT 
    n.n_name AS nation,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_quantity) AS avg_quantity,
    MAX(l.l_discount) AS max_discount,
    MIN(l.l_shipdate) AS earliest_ship_date
FROM 
    OrderHierarchy oh
JOIN 
    customer c ON oh.o_custkey = c.c_custkey
JOIN 
    supplier s ON c.c_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
WHERE 
    l.l_shipdate BETWEEN DATEADD(MONTH, -6, CURRENT_DATE) AND CURRENT_DATE
    AND (l.l_returnflag IS NULL OR l.l_returnflag != 'R')
GROUP BY 
    n.n_name
HAVING 
    total_revenue > (SELECT AVG(o_totalprice) FROM orders)
ORDER BY 
    total_revenue DESC
LIMIT 10;
