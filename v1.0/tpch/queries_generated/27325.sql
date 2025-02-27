SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    CONCAT('Supplier: ', s.s_name, ' supplies ', p.p_name, ' with a retail price of $', FORMAT(p.p_retailprice, 2), ' and available quantity of ', ps.ps_availqty, '.') AS detailed_info,
    SUBSTRING_INDEX(GROUP_CONCAT(DISTINCT CONCAT('Region: ', r.r_name, '; Nation: ', n.n_name) ORDER BY r.r_name SEPARATOR ' | '), '|', 3) AS regions_nations_info,
    COUNT(DISTINCT c.c_custkey) AS unique_customers
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
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
WHERE 
    p.p_retailprice > 500
    AND s.s_acctbal > 1000
GROUP BY 
    p.p_partkey, s.s_suppkey
HAVING 
    COUNT(DISTINCT c.c_custkey) > 0
ORDER BY 
    p.p_name, s.s_name DESC;
