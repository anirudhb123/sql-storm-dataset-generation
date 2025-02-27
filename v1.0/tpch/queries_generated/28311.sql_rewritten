SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    MAX(l.l_extendedprice) AS max_extended_price,
    MIN(l.l_discount) AS min_discount,
    SUM(CASE WHEN l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31' THEN l.l_quantity ELSE 0 END) AS total_quantity_shipped,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', SUBSTRING(s.s_address, 1, 20), ')'), '; ') AS supplier_details
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    p.p_type LIKE '%metal%' 
GROUP BY 
    p.p_name
ORDER BY 
    unique_suppliers DESC, average_supply_cost ASC
LIMIT 10;