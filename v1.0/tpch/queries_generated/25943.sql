SELECT 
    p.p_name, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    AVG(ps.ps_supplycost) AS avg_supply_cost, 
    SUBSTRING_INDEX(GROUP_CONCAT(DISTINCT s.s_name ORDER BY s.s_name SEPARATOR ', '), ',', 5) AS top_suppliers,
    CONCAT('Total:', CAST(SUM(l.l_extendedprice) AS CHAR)) AS total_sales,
    REGEXP_REPLACE(GROUP_CONCAT(DISTINCT n.n_name ORDER BY n.n_name SEPARATOR '; '), '([a-zA-Z]+)[^;]*', '\\1') AS unique_nations
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey 
JOIN 
    customer c ON l.l_orderkey = c.c_custkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
WHERE 
    p.p_retailprice > 50.00 
    AND s.s_acctbal > 1000.00 
GROUP BY 
    p.p_name 
HAVING 
    total_available_quantity > 100 
ORDER BY 
    supplier_count DESC, 
    total_sales DESC;
