SELECT
    p.p_name,
    COUNT(*) AS total_orders,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    MAX(l.l_discount) AS max_discount,
    MIN(l.l_tax) AS min_tax,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_phone, ')'), '; ') AS supplier_details
FROM
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE
    p.p_name LIKE '%the%' AND
    o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY
    p.p_name
ORDER BY
    total_quantity DESC
LIMIT 10;