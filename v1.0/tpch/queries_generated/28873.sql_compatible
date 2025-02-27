
SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    STRING_AGG(DISTINCT CONCAT(n.n_name, ' (', r.r_name, ')'), '; ') AS nation_region_info,
    AVG(p.p_retailprice) AS avg_retail_price,
    MAX(o.o_totalprice) AS max_order_price 
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
    p.p_retailprice > 20.00 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31' 
GROUP BY 
    s.s_name, p.p_name 
HAVING 
    SUM(ps.ps_availqty) > 100 
ORDER BY 
    AVG(p.p_retailprice) DESC;
