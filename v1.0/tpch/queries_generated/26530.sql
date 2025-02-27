WITH RECURSIVE name_parts AS (
    SELECT p_name, LENGTH(p_name) AS name_length, LOWER(p_name) AS name_lower
    FROM part
    WHERE LENGTH(p_name) > 10
    UNION ALL
    SELECT CONCAT(SUBSTRING(name_lower, 1, name_length - 1), 'X'), name_length - 1, LOWER(CONCAT(SUBSTRING(name_lower, 1, name_length - 1), 'X'))
    FROM name_parts
    WHERE name_length > 1
),
filtered_parts AS (
    SELECT p.partkey, p.p_name, np.name_lower, np.name_length
    FROM part p
    JOIN name_parts np ON LOWER(p.p_name) LIKE CONCAT('%', np.name_lower, '%')
)
SELECT
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    np.name_lower AS processed_part_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM filtered_parts np
JOIN partsupp ps ON np.partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN lineitem l ON l.l_partkey = np.partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
WHERE s.s_comment LIKE '%urgent%'
GROUP BY supplier_name, customer_name, processed_part_name
ORDER BY total_revenue DESC, supplier_name ASC;
