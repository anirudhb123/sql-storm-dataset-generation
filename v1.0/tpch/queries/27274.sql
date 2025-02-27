
SELECT 
    LEFT(p.p_name, 10) AS short_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    COUNT(DISTINCT s.s_name) AS total_suppliers,
    STRING_AGG(DISTINCT CONCAT(s.s_name, '(', s.s_phone, ')'), ', ') AS supplier_details,
    SUBSTRING(p.p_comment, 1, 15) AS short_comment,
    MAX(l.l_extendedprice) AS max_price,
    AVG(CASE 
            WHEN o.o_orderstatus = 'O' THEN o.o_totalprice 
            ELSE NULL 
        END) AS avg_open_order_price
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
GROUP BY 
    p.p_name, p.p_comment
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_available_quantity DESC;
