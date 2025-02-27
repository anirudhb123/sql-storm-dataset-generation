SELECT
    p.p_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(p.p_retailprice) AS avg_retail_price,
    STRING_AGG(DISTINCT CONCAT('Supplier: ', s.s_name, ' | Nation: ', n.n_name), '; ') AS supplier_details
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
WHERE
    p.p_comment LIKE '%fragile%'
AND
    p.p_size BETWEEN 10 AND 50
GROUP BY
    p.p_name
HAVING
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY
    avg_retail_price DESC;
