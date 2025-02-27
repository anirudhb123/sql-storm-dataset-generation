SELECT
    l_shipmode,
    SUM(l_quantity) AS total_quantity,
    SUM(l_extendedprice) AS total_extended_price,
    AVG(l_discount) AS average_discount
FROM
    lineitem
WHERE
    l_shipdate >= DATE '2022-01-01' AND l_shipdate < DATE '2023-01-01'
GROUP BY
    l_shipmode
ORDER BY
    total_quantity DESC;
