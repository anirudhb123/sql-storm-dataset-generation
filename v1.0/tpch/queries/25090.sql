SELECT 
    s.s_name AS supplier_name,
    COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied,
    SUM(ps.ps_availqty) AS total_available_quantity,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
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
    r.r_name = 'Asia' 
    AND p.p_retailprice > 10.00
    AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
GROUP BY 
    s.s_name
ORDER BY 
    total_parts_supplied DESC;
