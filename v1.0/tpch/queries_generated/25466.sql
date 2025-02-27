SELECT
    s.s_name AS supplier_name,
    COUNT(DISTINCT p.p_partkey) AS total_parts_supplied,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    STRING_AGG(DISTINCT SUBSTRING(s.s_address, 1, 15), ', ') AS abbreviated_addresses,
    CONCAT_WS(' - ', r.r_name, n.n_name) AS region_nation
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
    p.p_retailprice < 100.00
GROUP BY
    s.s_name, r.r_name, n.n_name
HAVING
    COUNT(DISTINCT p.p_partkey) > 5
ORDER BY
    total_parts_supplied DESC;
