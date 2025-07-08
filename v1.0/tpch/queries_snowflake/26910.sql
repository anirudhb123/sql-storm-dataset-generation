
SELECT 
    p.p_name,
    p.p_brand,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    CONCAT('Supplier Key: ', ps.ps_suppkey) AS supplier_info,
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    SUM(l.l_extendedprice) AS total_sales,
    AVG(l.l_discount) * 100 AS average_discount_percentage,
    MAX(s.s_acctbal) AS max_supplier_balance
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_name LIKE '%steel%'
    AND o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_comment, r.r_name, ps.ps_suppkey, s.s_acctbal
HAVING 
    COUNT(DISTINCT c.c_custkey) > 5
ORDER BY 
    total_sales DESC;
