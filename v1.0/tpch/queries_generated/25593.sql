SELECT
    CONCAT('Supplier: ', s_name, ' from Nation: ', n_name, ' with Products: ', GROUP_CONCAT(DISTINCT p_name SEPARATOR ', ')) AS supplier_info,
    SUM(ps_availqty) AS total_available_quantity,
    SUM(ps_supplycost * ps_availqty) AS total_supply_cost
FROM
    supplier s
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
WHERE
    p.p_size BETWEEN 20 AND 100
    AND p.p_retailprice > 50.00
GROUP BY
    s.s_suppkey, n.n_nationkey
ORDER BY
    total_supply_cost DESC
LIMIT 10;
