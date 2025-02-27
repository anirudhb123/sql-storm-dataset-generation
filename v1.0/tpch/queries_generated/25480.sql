SELECT
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(p.p_retailprice) AS average_retail_price,
    STRING_AGG(DISTINCT SUBSTRING(s.s_comment FROM 1 FOR 20) || '...' ORDER BY s.s_comment) AS supplier_comments
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE
    p.p_name LIKE '%Steel%'
GROUP BY
    p.p_name
HAVING
    COUNT(DISTINCT ps.ps_suppkey) > 5
ORDER BY
    total_available_quantity DESC;
