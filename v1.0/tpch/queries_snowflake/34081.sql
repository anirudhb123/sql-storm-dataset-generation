WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           0 AS hierarchy_level, 
           CAST(s.s_name AS VARCHAR(255)) AS full_name
    FROM supplier s
    WHERE s.s_nationkey IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           sh.hierarchy_level + 1,
           CAST(sh.full_name || ' -> ' || s.s_name AS VARCHAR(255))
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.hierarchy_level < 3
),
total_spent AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_custkey
),
average_customer_spend AS (
    SELECT AVG(total_amount) AS average_spending 
    FROM total_spent
),
supplier_part_availability AS (
    SELECT ps.ps_partkey, 
           SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT r.r_name, 
       n.n_name, 
       s.s_name, 
       COALESCE(sp.total_available, 0) AS available_quantity,
       CASE 
           WHEN ts.total_amount IS NULL THEN 'New Customer'
           ELSE CASE 
               WHEN ts.total_amount > (SELECT average_spending FROM average_customer_spend) THEN 'High Roller'
               ELSE 'Regular Customer'
           END
       END AS customer_type,
       sh.full_name AS supplier_hierarchy
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN total_spent ts ON s.s_suppkey = ts.o_custkey
LEFT JOIN supplier_part_availability sp ON sp.ps_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'Brand#1' LIMIT 1)
LEFT JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE r.r_name LIKE 'N%'
ORDER BY r.r_name, n.n_name, available_quantity DESC;
