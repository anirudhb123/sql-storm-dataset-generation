SELECT
    p.p_name,
    COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    SUM(l.l_quantity) AS total_quantity,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_address, ')'), '; ') AS supplier_details,
    CONCAT('Region: ', r.r_name, ' | Nation: ', n.n_name) AS location_info
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    customer c ON l.l_orderkey = c.c_custkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    p.p_type LIKE '%rubber%'
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY
    p.p_name, r.r_name, n.n_name
ORDER BY
    total_quantity DESC
LIMIT 10;