SELECT 
    CONCAT(c.c_name, ' from ', s.s_name, ' in ', r.r_name) AS supplier_customer_info,
    SUM(CAST(l.l_extendedprice * (1 - l.l_discount) AS decimal(12, 2))) AS total_sales,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(l.l_quantity) AS average_quantity,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
WHERE 
    r.r_name LIKE 'Asia%' 
    AND o.o_orderdate >= DATE '1996-01-01' 
    AND o.o_orderdate < DATE '1997-01-01'
GROUP BY 
    c.c_name, s.s_name, r.r_name
ORDER BY 
    total_sales DESC;