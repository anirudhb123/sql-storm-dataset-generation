SELECT
    s.s_name AS supplier_name,
    COUNT(DISTINCT ps.ps_partkey) AS total_parts,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    AVG(CASE WHEN LENGTH(ps.ps_comment) > 50 THEN LENGTH(ps.ps_comment) ELSE NULL END) AS avg_long_comment_length,
    STRING_AGG(DISTINCT p.p_name, ', ') FILTER (WHERE p.p_brand = 'Brand#45') AS part_names_brand_45
FROM
    supplier s
JOIN
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    r.r_name LIKE 'EUROPE%'
GROUP BY
    s.s_suppkey, s.s_name
HAVING
    COUNT(DISTINCT ps.ps_partkey) > 5
ORDER BY
    total_supply_cost DESC, avg_long_comment_length ASC;
