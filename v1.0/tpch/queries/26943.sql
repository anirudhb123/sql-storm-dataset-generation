SELECT 
    s.s_name AS supplier_name,
    COUNT(DISTINCT p.p_partkey) AS total_parts,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    MAX(p.p_retailprice) AS max_price,
    MIN(p.p_retailprice) AS min_price,
    AVG(p.p_retailprice) AS avg_price,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_served
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
    s.s_acctbal > 1000.00
GROUP BY 
    s.s_suppkey, s.s_name
HAVING 
    COUNT(DISTINCT p.p_partkey) > 5
ORDER BY 
    total_supply_cost DESC;
