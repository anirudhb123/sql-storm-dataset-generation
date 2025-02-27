SELECT 
    p.p_name AS part_name,
    p.p_brand AS part_brand,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_qty,
    AVG(p.p_retailprice) AS average_retail_price,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    SUM(o.o_totalprice) AS total_sales,
    SUBSTR(p.p_comment, 1, 20) AS short_comment
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
WHERE 
    p.p_retailprice > 50.00
    AND o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_sales DESC
LIMIT 10;
