WITH RECURSIVE RegionHierarchy AS (
    SELECT r_regionkey, r_name, 0 AS level
    FROM region
    WHERE r_name LIKE 'A%'
    UNION ALL
    SELECT r.r_regionkey, r.r_name, rh.level + 1
    FROM region r
    JOIN RegionHierarchy rh ON r.r_regionkey = rh.r_regionkey
)
SELECT
    c.c_name AS customer_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
    COUNT(DISTINCT o.o_orderkey) AS num_orders,
    MAX(l.l_shipdate) AS last_purchase_date,
    ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank,
    CASE 
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) IS NULL THEN 'No purchases'
        ELSE 'Regular customer'
    END AS customer_status
FROM
    customer c
LEFT JOIN
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
WHERE
    l.l_shipdate >= '2022-01-01'
    AND l.l_shipdate <= CURRENT_DATE
GROUP BY
    c.c_custkey, c.c_name, c.c_nationkey
HAVING
    SUM(l.l_extendedprice * (1 - l.l_discount)) > (SELECT AVG(total) FROM (
        SELECT SUM(l_extendedprice * (1 - l_discount)) AS total
        FROM lineitem
        GROUP BY l_orderkey
    ) AS averages) 
    OR COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY
    total_spent DESC
LIMIT 10;
