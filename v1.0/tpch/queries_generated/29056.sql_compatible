
SELECT
    p.p_name,
    s.s_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(p.p_retailprice) AS average_retail_price,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    r.r_name AS region_name
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    customer c ON s.s_nationkey = c.c_nationkey
JOIN
    nation n ON c.c_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
JOIN
    orders o ON c.c_custkey = o.o_custkey
WHERE
    p.p_type LIKE '%brass%'
    AND s.s_comment NOT LIKE '%fragile%'
    AND o.o_orderstatus = 'O'
GROUP BY
    p.p_name,
    s.s_name,
    r.r_name
HAVING
    SUM(ps.ps_availqty) > 50
ORDER BY
    AVG(p.p_retailprice) DESC,
    SUM(ps.ps_availqty) ASC;
