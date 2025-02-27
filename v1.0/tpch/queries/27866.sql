SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_avail_qty,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    MAX(p.p_retailprice) AS max_retail_price,
    STRING_AGG(DISTINCT s.s_name || ' (' || s.s_address || ')', ', ') AS supplier_details
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_size > 10 
    AND s.s_acctbal > 1000.00
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 5
ORDER BY 
    total_avail_qty DESC;
