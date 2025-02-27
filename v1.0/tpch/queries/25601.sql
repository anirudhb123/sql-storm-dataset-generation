SELECT
    COUNT(DISTINCT p.p_partkey) AS unique_parts,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names,
    r.r_name AS region_name,
    n.n_name AS nation_name,
    p.p_brand AS part_brand
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
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
WHERE
    p.p_size BETWEEN 5 AND 20
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND r.r_name LIKE 'EU%'
GROUP BY
    r.r_name, n.n_name, p.p_brand
HAVING
    SUM(l.l_quantity) > 1000
ORDER BY
    total_supply_cost DESC;