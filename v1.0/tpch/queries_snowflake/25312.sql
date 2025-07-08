
SELECT 
    s.s_name AS supplier_name, 
    p.p_name AS part_name, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    AVG(ps.ps_supplycost) AS average_supply_cost, 
    LISTAGG(DISTINCT CONCAT(n.n_name, ' (', r.r_name, ')'), ', ') WITHIN GROUP (ORDER BY n.n_name) AS nation_region_info
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
WHERE 
    p.p_size BETWEEN 10 AND 20 
    AND s.s_acctbal > 1000 
GROUP BY 
    s.s_name, p.p_name 
HAVING 
    SUM(ps.ps_availqty) > 500 
ORDER BY 
    total_available_quantity DESC;
