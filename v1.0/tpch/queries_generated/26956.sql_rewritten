SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_quantity) AS total_quantity,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment,
    CASE 
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000 THEN 'High Value'
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS value_category
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
    p.p_brand LIKE 'Brand%'
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, c.c_name, p.p_comment
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC, p.p_name ASC;