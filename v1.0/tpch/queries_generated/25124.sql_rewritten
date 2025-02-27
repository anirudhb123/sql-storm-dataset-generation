SELECT 
    CONCAT(n.n_name, ' - ', r.r_name) AS nation_region,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    SUM(CASE 
        WHEN LENGTH(p.p_name) > 20 THEN p.p_retailprice 
        ELSE 0 
    END) AS total_retail_price_large_name,
    ROUND(AVG(l.l_extendedprice * (1 - l.l_discount)), 2) AS avg_sales_price,
    STRING_AGG(DISTINCT p.p_comment, ', ') AS part_comments
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
JOIN 
    orders o ON o.o_custkey = c.c_custkey
JOIN 
    lineitem l ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON ps.ps_partkey = l.l_partkey
JOIN 
    part p ON p.p_partkey = ps.ps_partkey
WHERE 
    l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1997-12-31'
GROUP BY 
    n.n_name, r.r_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 10
ORDER BY 
    nation_region;