WITH RECURSIVE name_split AS (
    SELECT s.s_name AS original_name, 
           s.s_suppkey,
           SUBSTRING_INDEX(s.s_name, ' ', 1) AS first_name,
           SUBSTRING_INDEX(s.s_name, ' ', -1) AS last_name,
           1 AS depth
    FROM supplier s
    UNION ALL
    SELECT s.original_name, 
           s.s_suppkey,
           SUBSTRING_INDEX(s.original_name, ' ', depth + 1),
           SUBSTRING_INDEX(s.original_name, ' ', -1),
           depth + 1
    FROM name_split s
    WHERE CHAR_LENGTH(s.original_name) - CHAR_LENGTH(REPLACE(s.original_name, ' ', '')) >= depth
),
agg_names AS (
    SELECT s_suppkey, 
           GROUP_CONCAT(first_name SEPARATOR ', ') AS first_names,
           GROUP_CONCAT(last_name SEPARATOR ', ') AS last_names
    FROM name_split
    GROUP BY s_suppkey
)
SELECT p.p_name,
       r.r_name,
       c.c_name,
       agg.first_names,
       agg.last_names,
       COUNT(o.o_orderkey) AS total_orders,
       SUM(l.l_extendedprice) AS total_revenue
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN region r ON s.s_nationkey = r.r_regionkey
JOIN customer c ON c.c_nationkey = s.s_nationkey
JOIN orders o ON o.o_custkey = c.c_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN agg_names agg ON s.s_suppkey = agg.s_suppkey
WHERE p.p_name LIKE '%steel%'
GROUP BY p.p_name, r.r_name, c.c_name, agg.first_names, agg.last_names
HAVING total_orders > 5
ORDER BY total_revenue DESC;
