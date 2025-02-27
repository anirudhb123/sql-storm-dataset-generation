SELECT
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    CONCAT('Supplier: ', s.s_name, '; Part: ', p.p_name, '; Region: ', r.r_name) AS detailed_info,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    STRING_AGG(DISTINCT CONCAT('Order Date: ', o.o_orderdate, ', Total Price: ', o.o_totalprice), '; ') AS orders_info
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
LEFT JOIN
    lineitem li ON p.p_partkey = li.l_partkey
LEFT JOIN
    orders o ON li.l_orderkey = o.o_orderkey
WHERE
    p.p_comment LIKE '%red%'
GROUP BY
    p.p_name, s.s_name, r.r_name
ORDER BY
    total_available_quantity DESC;
