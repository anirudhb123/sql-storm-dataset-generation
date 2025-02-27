SELECT 
    p.p_brand,
    COUNT(DISTINCT ps.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    STRING_AGG(DISTINCT SUBSTRING(s.s_name FROM 1 FOR 15), ', ') AS supplier_names,
    SUM(CASE WHEN l.l_discount > 0.1 THEN l.l_extendedprice * l.l_discount ELSE 0 END) AS total_discounted_price
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    p.p_type LIKE '%brass%'
    AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
GROUP BY 
    p.p_brand
HAVING 
    COUNT(DISTINCT ps.s_suppkey) > 5
ORDER BY 
    total_available_quantity DESC
LIMIT 10;
