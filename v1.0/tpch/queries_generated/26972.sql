SELECT 
    p.p_brand,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(p.p_retailprice) AS avg_retail_price,
    SUM(l.l_quantity) AS total_quantity_sold,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUBSTRING(p.p_name, 1, 10) AS short_part_name,
    GROUP_CONCAT(DISTINCT r.r_name ORDER BY r.r_name) AS regions_supplied
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
GROUP BY 
    p.p_brand, short_part_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_revenue DESC
LIMIT 10;
