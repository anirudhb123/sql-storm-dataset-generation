WITH RECURSIVE account_hierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, s_comment, 0 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, ah.level + 1
    FROM supplier s
    JOIN account_hierarchy ah ON s.s_suppkey = ah.s_suppkey
    WHERE ah.level < 10
),
filtered_parts AS (
    SELECT p_partkey, p_name, SUBSTRING(p_comment FROM 1 FOR 20) AS short_comment, 
           p_size * p_retailprice AS calculated_value,
           CASE WHEN p_size IS NULL THEN 'Unknown Size' ELSE CAST(p_size AS VARCHAR) END AS size_info
    FROM part
    WHERE p_retailprice > (SELECT AVG(p_retailprice) FROM part WHERE p_size IS NOT NULL)
),
ranked_orders AS (
    SELECT o_orderkey, o_custkey, o_totalprice, 
           RANK() OVER (PARTITION BY o_custkey ORDER BY o_orderdate DESC) AS order_rank
    FROM orders
),
outer_joined AS (
    SELECT p.p_partkey, p.short_comment, o.o_orderkey, 
           CASE WHEN o.o_orderkey IS NULL THEN 'No Orders' ELSE 'Has Orders' END AS order_status
    FROM filtered_parts p
    LEFT OUTER JOIN ranked_orders o ON p.p_partkey = o.o_orderkey
    ORDER BY p.p_partkey
)
SELECT r.r_name, COUNT(DISTINCT o.o_orderkey) AS order_count, 
       SUM(p.calculated_value) AS total_retail_value,
       JSON_AGG(ROW_TO_JSON(outer_joined)) AS part_order_details
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN outer_joined o ON s.s_suppkey = o.o_orderkey
WHERE r.r_name LIKE 'N%'
GROUP BY r.r_name
HAVING COUNT(DISTINCT o.o_orderkey) > 1 
   OR MAX(s.s_acctbal) IS NULL
ORDER BY total_retail_value DESC
LIMIT 10;
