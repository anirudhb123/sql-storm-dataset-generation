
SELECT 
    CONCAT('Supplier ', s.s_name, ' from ', r.r_name, ' has supplied ', COUNT(p.p_partkey), ' parts: ', STRING_AGG(p.p_name, ', ')) AS supplier_info,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
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
    p.p_retailprice > 100.00
GROUP BY 
    s.s_suppkey, s.s_name, r.r_name, r.r_regionkey
HAVING 
    SUM(ps.ps_supplycost * ps.ps_availqty) > 5000.00
ORDER BY 
    total_supply_cost DESC;
