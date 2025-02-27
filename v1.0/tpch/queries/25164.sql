SELECT 
    CONCAT('Supplier: ', s.s_name, ', Address: ', s.s_address, ', Nation: ', n.n_name) AS supplier_info,
    SUM(ps.ps_availqty) AS total_available_quantity,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    COUNT(DISTINCT ps.ps_partkey) AS distinct_part_count,
    STRING_AGG(DISTINCT CONCAT('Part Name: ', p.p_name, ', Price: ', p.p_retailprice), '; ') AS part_details
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    AND p.p_size BETWEEN 10 AND 20
GROUP BY 
    s.s_suppkey, s.s_name, s.s_address, n.n_name
ORDER BY 
    total_supply_cost DESC;
