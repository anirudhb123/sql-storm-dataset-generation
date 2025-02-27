SELECT
    SUBSTRING(p_name, 1, 10) AS short_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(ps_supplycost) AS average_supply_cost,
    CONCAT('Retail Price: $', FORMAT(ROUND(p_retailprice, 2), 2)) AS formatted_price,
    TRIM(CONCAT(n.n_name, ', ', r.r_name)) AS full_region_name
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    customer c ON c.c_nationkey = s.s_nationkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    LENGTH(p.p_comment) > 10
GROUP BY
    p.p_partkey, short_name
ORDER BY
    average_supply_cost DESC
LIMIT 50;
