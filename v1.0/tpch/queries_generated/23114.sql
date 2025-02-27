WITH RECURSIVE dynamic_supplier AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS recursion_level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal * 1.1 AS s_acctbal, recursion_level + 1
    FROM supplier s
    JOIN dynamic_supplier ds ON s.s_suppkey = ds.s_suppkey
    WHERE recursion_level < 3
), 
part_supplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE ps.ps_availqty > 0
), 
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
), 
ranked_customers AS (
    SELECT c.c_custkey, c.c_name, c.order_count, c.total_spent,
           RANK() OVER (ORDER BY c.total_spent DESC) AS rnk
    FROM customer_orders c
    WHERE c.order_count > 1
)
SELECT ps.p_partkey, ps.p_name, ps.ps_supplycost, ps.ps_availqty, ds.s_name,
       CASE WHEN ds.s_acctbal IS NULL THEN 'N/A' 
            ELSE FORMAT(ds.s_acctbal, 'C') END AS formatted_acctbal,
       COALESCE(rc.total_spent / NULLIF(rc.order_count, 0), 0) AS avg_spent,
       ROW_NUMBER() OVER (PARTITION BY ps.p_partkey ORDER BY ps.ps_supplycost ASC) AS supply_rank
FROM part_supplier ps
LEFT JOIN dynamic_supplier ds ON ps.s_name = ds.s_name
LEFT JOIN ranked_customers rc ON rc.rnk < 5
WHERE ps.ps_supplycost IS NOT NULL AND ps.ps_availqty > 10
  AND (ds.s_acctbal BETWEEN 100 AND 10000 OR ds.s_acctbal IS NULL)
ORDER BY ps.p_partkey, supply_rank
LIMIT 100 OFFSET 20
