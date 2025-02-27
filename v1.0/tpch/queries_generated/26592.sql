SELECT
    CONCAT(s.s_name, ' (' , s.s_nationkey, ')') AS supplier_info,
    SUM(CASE 
        WHEN p.p_brand LIKE 'Brand#%' THEN l.l_quantity 
        ELSE 0 
    END) AS total_brand_quantity,
    COUNT(DISTINCT CASE 
        WHEN c.c_mktsegment = 'BUILDING' THEN o.o_orderkey 
        END) AS building_orders_count,
    AVG(l.l_discount) AS average_discount,
    JSON_ARRAYAGG(DISTINCT p.p_type) AS unique_part_types
FROM
    supplier s
JOIN
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
WHERE
    s.s_acctbal > 1000
GROUP BY
    s.s_suppkey
HAVING
    total_brand_quantity > 0
ORDER BY
    average_discount DESC
LIMIT 10;
