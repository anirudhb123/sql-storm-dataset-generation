SELECT 
    p.p_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(p.p_retailprice) AS average_retail_price,
    COUNT(DISTINCT s.s_suppkey) AS number_of_suppliers,
    STRING_AGG(DISTINCT s.s_name, '; ') AS supplier_names,
    MAX(o.o_totalprice) AS max_order_total,
    ARRAY_AGG(DISTINCT c.c_mktsegment) AS market_segments,
    MIN(p.p_size) AS smallest_part_size,
    CONCAT('Region: ', r.r_name, ', Nation: ', n.n_name) AS region_nation_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
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
    p.p_comment LIKE '%fragile%'
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, r.r_name, n.n_name
ORDER BY 
    total_available_quantity DESC, average_retail_price ASC;