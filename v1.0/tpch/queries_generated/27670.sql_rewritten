SELECT
    CONCAT(s.s_name, ' from ', n.n_name, ' in the region of ', r.r_name) AS supplier_info,
    COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    AVG(CASE 
            WHEN l.l_discount BETWEEN 0.05 AND 0.10 THEN l.l_extendedprice 
            ELSE 0 
        END) AS avg_discounted_price,
    STRING_AGG(DISTINCT p.p_type, ', ') AS part_types_supplied,
    MAX(o.o_totalprice) AS max_order_value
FROM
    supplier s
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
JOIN
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
JOIN
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
WHERE
    p.p_retailprice > 30.00
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY
    s.s_name, n.n_name, r.r_name
HAVING
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY
    total_supply_cost DESC;