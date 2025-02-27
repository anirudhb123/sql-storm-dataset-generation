SELECT 
    supplier.s_name,
    COUNT(DISTINCT partsupp.ps_partkey) AS total_parts,
    SUM(partsupp.ps_supplycost * partsupp.ps_availqty) AS total_supply_cost,
    STRING_AGG(DISTINCT part.p_name, ', ') AS part_names,
    MAX(part.p_retailprice) AS max_retail_price,
    MIN(part.p_retailprice) AS min_retail_price
FROM 
    supplier
JOIN 
    partsupp ON supplier.s_suppkey = partsupp.ps_suppkey
JOIN 
    part ON partsupp.ps_partkey = part.p_partkey
GROUP BY 
    supplier.s_name
HAVING 
    COUNT(DISTINCT part.p_partkey) > 5
ORDER BY 
    total_supply_cost DESC;
