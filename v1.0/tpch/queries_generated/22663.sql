WITH RECURSIVE supplier_tree AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL AND s_acctbal > 5000.00

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, st.level + 1
    FROM supplier s
    JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
    JOIN supplier_tree st ON ps.ps_partkey = (SELECT p_partkey FROM part p WHERE p.p_retailprice > 100.00 AND p.p_size BETWEEN 1 AND 10 LIMIT 1)
    WHERE s.s_acctbal < st.s_acctbal AND st.level < 5
),
orders_with_largest_customers AS (
    SELECT o.o_orderkey, o.o_custkey, COALESCE(SUM(l.l_discount * l.l_extendedprice), 0) AS total_discount
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
    HAVING total_discount IS NOT NULL
),
cross_joins AS (
    SELECT c.c_custkey, c.c_name, o.total_discount, ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.total_discount DESC) as rn
    FROM customer c
    LEFT JOIN orders_with_largest_customers o ON c.c_custkey = o.o_custkey
),
filtered_customers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           CASE 
               WHEN c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2) THEN 'Above Average'
               ELSE 'Below Average'
           END AS acctbal_category
    FROM customer c
    WHERE c.c_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name LIKE '%land%')
),
final_selection AS (
    SELECT st.s_name, fc.c_name, fc.acctbal_category, st.level
    FROM supplier_tree st
    INNER JOIN filtered_customers fc ON st.s_nationkey = fc.c_custkey
    WHERE st.level = (SELECT MAX(level) FROM supplier_tree)
)
SELECT f.s_name, f.c_name, f.acctbal_category, 
       CASE WHEN f.acctbal_category = 'Above Average' THEN 'Elite Member' 
            ELSE 'Regular Member' END AS member_status,
       CASE WHEN f.level IS NULL THEN 'No Level' 
            ELSE f.level END AS supply_level
FROM final_selection f
FULL OUTER JOIN (SELECT DISTINCT n.n_name FROM nation n WHERE n.n_comment IS NULL) n ON n.n_name IS NULL
WHERE f.c_name IS NOT NULL
ORDER BY f.member_status, f.s_name;
