SELECT
    p.p_brand,
    COUNT(DISTINCT ps.s_suppkey) AS supplier_count,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY
    p.p_brand
ORDER BY
    supplier_count DESC
LIMIT 10;
