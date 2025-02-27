
SELECT
    CONCAT('Supplier: ', s.s_name, ' from Nation: ', n.n_name, ' with Products: ', STRING_AGG(DISTINCT p.p_name, ', ')) AS supplier_info,
    SUM(ps.ps_availqty) AS total_available_quantity,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
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
    s.s_suppkey, s.s_name, n.n_nationkey, n.n_name
ORDER BY
    total_supply_cost DESC
LIMIT 10;
