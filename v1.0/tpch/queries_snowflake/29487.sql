
SELECT 
    CONCAT(s.s_name, ' from ', n.n_name, ' supplies ', COUNT(DISTINCT ps.ps_partkey), ' parts') AS supplier_info,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    MAX(p.p_retailprice) AS max_part_price,
    MIN(p.p_retailprice) AS min_part_price,
    AVG(p.p_retailprice) AS avg_part_price,
    LISTAGG(DISTINCT p.p_name, ', ') WITHIN GROUP (ORDER BY p.p_name ASC) AS part_names
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    LENGTH(s.s_name) > 10 AND 
    s.s_acctbal > 100.00 AND 
    p.p_size IN (1, 2, 3, 4, 5)
GROUP BY 
    s.s_name, n.n_name
HAVING 
    SUM(ps.ps_supplycost * ps.ps_availqty) > 1000
ORDER BY 
    total_supply_cost DESC;
