
WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_shippriority,
        1 AS depth
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT 
        oh.o_orderkey,
        oh.o_orderdate,
        oh.o_totalprice,
        oh.o_shippriority,
        depth + 1
    FROM 
        OrderHierarchy oh
    JOIN 
        lineitem l ON oh.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'R'
)

SELECT 
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    RANK() OVER (PARTITION BY p.p_brand ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS brand_rank,
    COUNT(DISTINCT CASE WHEN c.c_mktsegment IS NULL THEN 'NULL Segment' ELSE c.c_mktsegment END) AS null_segment_count
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_size BETWEEN 1 AND 10
    AND (s.s_acctbal IS NOT NULL OR 1 IS NULL)
GROUP BY 
    p.p_name, p.p_brand
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > (
        SELECT 
            AVG(total_revenue) 
        FROM (
            SELECT 
                SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue 
            FROM 
                lineitem l 
            JOIN 
                orders o ON l.l_orderkey = o.o_orderkey 
            WHERE 
                o.o_orderdate BETWEEN '1998-01-01' AND '1999-01-01'
            GROUP BY 
                l.l_orderkey
        ) AS revenue_summary
    )
ORDER BY 
    brand_rank, revenue DESC
LIMIT 5;
