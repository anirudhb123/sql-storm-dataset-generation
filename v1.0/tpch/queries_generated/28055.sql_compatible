
SELECT 
    p.p_name,
    COUNT(*) AS total_supply,
    SUM(ps.ps_availqty) AS total_available_quantity,
    ROUND(AVG(l.l_discount), 2) AS average_discount,
    MAX(l.l_shipdate) AS latest_ship_date,
    MIN(l.l_shipdate) AS earliest_ship_date,
    STRING_AGG(DISTINCT s.s_name, '; ') AS supplier_names,
    SUBSTRING(p.p_comment, 1, 23) AS short_comment
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
WHERE 
    p.p_size >= 10 
    AND s.s_acctbal > 5000
GROUP BY 
    p.p_name, p.p_comment
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 5
ORDER BY 
    total_supply DESC, 
    average_discount ASC;
