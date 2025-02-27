WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > 10000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 5000 AND sh.level < 3
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-10-01'
    GROUP BY c.c_custkey, c.c_name
),
part_supplier AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_partkey
),
ranked_customers AS (
    SELECT c.c_custkey, c.c_name, c.mktsegment, COALESCE(co.total_spent, 0) AS total_spent,
           RANK() OVER (PARTITION BY c.mktsegment ORDER BY COALESCE(co.total_spent, 0) DESC) AS rank
    FROM customer c
    LEFT JOIN customer_orders co ON c.c_custkey = co.c_custkey
),
region_nations AS (
    SELECT r.r_name, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name, n.n_name
)

SELECT rc.mktsegment, rc.c_name, rc.total_spent, sh.s_name AS high_balance_supplier,
       rh.r_name AS region, rh.n_name AS nation, rh.supplier_count,
       CASE 
           WHEN rc.total_spent > 10000 THEN 'High Value Customer'
           WHEN rc.total_spent BETWEEN 5000 AND 10000 THEN 'Medium Value Customer'
           ELSE 'Low Value Customer'
       END AS customer_value
FROM ranked_customers rc
LEFT JOIN supplier_hierarchy sh ON sh.s_acctbal > rc.total_spent AND sh.level = 0
JOIN region_nations rh ON sh.s_nationkey = rh.r_nationkey 
WHERE rc.rank = 1
ORDER BY rc.mktsegment, rc.total_spent DESC;
