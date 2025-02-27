SELECT
    s.s_name AS supplier_name,
    COUNT(DISTINCT p.p_partkey) AS unique_parts_supplied,
    SUM(ps.ps_availqty) AS total_available_quantity,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    STRING_AGG(DISTINCT (TRIM(CONCAT('Part: ', p.p_name))) , '; ') AS part_names_combined,
    AVG(CASE WHEN c.c_mktsegment = 'BUILDING' THEN o.o_totalprice ELSE NULL END) AS avg_order_price_building,
    MAX(CASE WHEN o.o_orderstatus = 'O' THEN o.o_totalprice ELSE NULL END) AS max_open_order_price
FROM
    supplier s
JOIN
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    customer c ON c.c_nationkey = n.n_nationkey
JOIN
    orders o ON c.c_custkey = o.o_custkey
WHERE
    p.p_retailprice > 100.00
GROUP BY
    s.s_name
HAVING
    COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY
    total_supply_cost DESC;
