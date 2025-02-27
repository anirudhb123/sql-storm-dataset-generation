SELECT
    p.p_name,
    p.p_brand,
    p.p_type,
    COUNT(DISTINCT ps.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    STRING_AGG(DISTINCT SUBSTRING(s.s_name, 1, 10), ', ') AS supplier_names,
    STRING_AGG(DISTINCT SUBSTRING(r.r_name, 1, 15), ', ') AS region_names
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    p.p_retailprice > 50.00
    AND p.p_comment LIKE '%premium%'
GROUP BY
    p.p_partkey, p.p_name, p.p_brand, p.p_type
HAVING
    COUNT(DISTINCT n.n_nationkey) > 1
ORDER BY
    supplier_count DESC, total_available_quantity DESC;
