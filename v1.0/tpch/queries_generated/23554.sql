WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        CAST(o.o_orderkey AS VARCHAR) AS hierarchy
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1994-01-01' 
        AND o.o_orderstatus = 'O'
    UNION ALL
    SELECT 
        o.o_orderkey,
        oh.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        CONCAT(oh.hierarchy, ' -> ', o.o_orderkey) AS hierarchy
    FROM 
        orders o
    JOIN 
        OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE 
        o.o_orderdate > oh.o_orderdate
)
SELECT 
    n.n_name AS nation_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT oh.o_orderkey) AS order_count,
    MAX(oh.o_orderdate) AS latest_order_date,
    COUNT(DISTINCT s.s_suppkey) FILTER (WHERE s.s_acctbal IS NOT NULL) AS unique_suppliers,
    COUNT(DISTINCT CASE WHEN c.c_mktsegment = 'AUTOMOBILE' THEN c.c_custkey END) AS auto_customers,
    STRING_AGG(DISTINCT p.p_name, ', ') FILTER (WHERE p.p_size BETWEEN 10 AND 20) AS selected_parts
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT OUTER JOIN 
    OrderHierarchy oh ON oh.o_orderkey = o.o_orderkey
WHERE 
    l.l_shipdate >= '1993-01-01'
GROUP BY 
    n.n_name
HAVING 
    SUM(l.l_extendedprice) BETWEEN 1000000 AND 5000000
ORDER BY 
    total_revenue DESC
LIMIT 10;
