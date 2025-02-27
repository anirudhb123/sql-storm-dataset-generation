WITH RECURSIVE part_costs AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty,
           (ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rnk
    FROM part p 
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 10
),
regional_nations AS (
    SELECT n.n_nationkey, n.n_name, r.r_regionkey, r.r_name
    FROM nation n 
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE r.r_name IS NOT NULL
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS spending_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
supplier_info AS (
    SELECT s.s_suppkey, s.s_name, COALESCE(SUM(ps.ps_supplycost), 0) AS total_supplycost
    FROM supplier s 
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
nations_above_avg AS (
    SELECT n.n_name
    FROM regional_nations n
    JOIN customer_orders co ON n.n_nationkey = co.n_nationkey
    GROUP BY n.n_name
    HAVING AVG(co.total_spent) > (SELECT AVG(total_spent) FROM customer_orders)
)
SELECT DISTINCT pc.p_partkey, pc.p_name, pc.total_cost, 
       CASE 
           WHEN n.n_name IS NOT NULL THEN 'Exists' 
           ELSE 'Not Exists' 
       END AS nation_check,
       s.total_supplycost
FROM part_costs pc
LEFT JOIN nations_above_avg n ON pc.total_cost > 5000 AND n.n_name IS NOT NULL
FULL OUTER JOIN supplier_info s ON pc.p_partkey = s.s_suppkey
WHERE pc.rnk = 1
AND s.total_supplycost IS NOT NULL
ORDER BY pc.total_cost DESC, s.total_supplycost ASC;
