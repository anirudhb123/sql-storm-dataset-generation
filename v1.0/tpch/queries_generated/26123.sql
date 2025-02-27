SELECT 
    s.s_name AS supplier_name,
    COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    GROUP_CONCAT(DISTINCT CONCAT(p.p_name, ' (', p.p_brand, ')') ORDER BY p.p_name SEPARATOR ', ') AS part_names,
    MAX(s.s_acctbal) AS max_account_balance,
    MIN(s.s_acctbal) AS min_account_balance,
    SUBSTRING_INDEX(GROUP_CONCAT(DISTINCT r.r_name ORDER BY r.r_name SEPARATOR '; '), '; ', 3) AS top_regions,
    COUNT(DISTINCT c.c_custkey) AS unique_customers
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size BETWEEN 1 AND 20)
    AND s.s_acctbal > 1000
GROUP BY 
    s.s_name
HAVING 
    unique_parts > 3
ORDER BY 
    total_available_quantity DESC;
