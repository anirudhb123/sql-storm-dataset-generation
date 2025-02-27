SELECT
    s_name,
    COUNT(DISTINCT p_partkey) AS unique_parts,
    SUM(ps_availqty) AS total_available_quantity,
    AVG(p_retailprice) AS average_retail_price,
    STRING_AGG(DISTINCT CONCAT(CAST(p_name AS VARCHAR(100)), ' (', p_type, ')'), '; ') AS formatted_items,
    r_name
FROM
    supplier
JOIN
    partsupp ON s_suppkey = ps_suppkey
JOIN
    part ON ps_partkey = p_partkey
JOIN
    nation ON s_nationkey = n_nationkey
JOIN
    region ON n_regionkey = r_regionkey
WHERE
    p_retailprice > 50.00
GROUP BY
    s_name, r_name
HAVING
    COUNT(DISTINCT p_partkey) > 5
ORDER BY
    total_available_quantity DESC;
