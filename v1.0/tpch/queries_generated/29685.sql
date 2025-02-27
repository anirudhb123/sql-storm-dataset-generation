SELECT 
    CONCAT(c.c_name, ' - ', s.s_name) AS customer_supplier,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUBSTRING_INDEX(p.p_name, ' ', 1) AS part_first_word,
    r.r_name AS region_name
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
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    r.r_name LIKE 'S%' AND
    o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    customer_supplier, part_first_word, region_name
HAVING 
    total_sales > 10000
ORDER BY 
    total_sales DESC, part_first_word;
