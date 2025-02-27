SELECT 
    CONCAT(s.s_name, ' from ', n.n_name, ' region, ', r.r_name) AS supplier_region_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS orders_count,
    AVG(CASE 
        WHEN c.c_mktsegment = 'BUILDING' THEN l.l_extendedprice 
        ELSE NULL 
    END) AS avg_price_building,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name LIKE '%East%'
    AND l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    supplier_region_name
ORDER BY 
    total_revenue DESC
LIMIT 10;