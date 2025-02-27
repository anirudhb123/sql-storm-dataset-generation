SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_type,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(CASE 
            WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) 
            ELSE 0 
        END) AS total_returned_sales,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment,
    CONCAT('Nation: ', n.n_name, ' | Region: ', r.r_name) AS nation_region_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_brand LIKE 'Brand%Organic%' AND 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_comment, n.n_name, r.r_name
ORDER BY 
    total_returned_sales DESC, supplier_count DESC;