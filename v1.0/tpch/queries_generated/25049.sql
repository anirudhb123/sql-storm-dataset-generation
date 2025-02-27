SELECT 
    p.p_name, 
    COUNT(DISTINCT ps.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    RANK() OVER (ORDER BY SUM(ps.ps_availqty) DESC) AS availability_rank
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
WHERE 
    CHARINDEX('Steel', p.p_type) > 0
    AND r.r_name LIKE 'Asia%' 
    AND p.p_retailprice > 50.00
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 2
ORDER BY 
    total_available_quantity DESC;
