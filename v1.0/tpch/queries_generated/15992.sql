SELECT
    p.p_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
GROUP BY
    p.p_name
HAVING
    total_available_quantity > 100
ORDER BY
    average_supply_cost DESC;
