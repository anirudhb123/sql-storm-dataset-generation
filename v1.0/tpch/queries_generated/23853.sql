WITH RECURSIVE part_supplier_cte AS (
    SELECT ps.ps_partkey, 
           ps.ps_suppkey, 
           ps.ps_availqty, 
           ps.ps_supplycost, 
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) AS rank
    FROM partsupp ps
    WHERE ps.ps_availqty > 0
    UNION ALL
    SELECT ps.ps_partkey, 
           ps.ps_suppkey, 
           ps.ps_availqty, 
           ps.ps_supplycost, 
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) AS rank
    FROM partsupp ps
    JOIN part_supplier_cte pcte ON pcte.ps_partkey = ps.ps_partkey
    WHERE pcte.rank < 5 AND ps.ps_supplycost < pcte.ps_supplycost
),
nation_stats AS (
    SELECT n.n_nationkey,
           n.n_name,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(s.s_acctbal) AS total_account_balance
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
customer_orders AS (
    SELECT c.c_custkey,
           c.c_name,
           SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS spending_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
supply_details AS (
    SELECT p.p_partkey,
           p.p_name,
           SUM(COALESCE(ps.ps_availqty, 0)) AS total_avail_qty,
           SUM(COALESCE(ps.ps_supplycost, 0)) / NULLIF(SUM(COALESCE(ps.ps_availqty, 0)), 0) AS avg_supply_cost_per_qty
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT ns.n_name AS nation_name,
       cs.c_name AS customer_name,
       cs.total_spent,
       spr.avg_supply_cost_per_qty,
       CASE 
           WHEN cs.total_spent > (SELECT AVG(total_spent) FROM customer_orders) THEN 'High Roller'
           ELSE 'Regular'
       END AS spending_category,
       COUNT(DISTINCT p.p_partkey) OVER (PARTITION BY ns.n_nationkey) AS part_count_per_nation,
       MAX(sp.total_avail_qty) OVER (PARTITION BY ns.n_nationkey) AS max_available_quantity
FROM nation_stats ns
JOIN customer_orders cs ON ns.supplier_count > 0
LEFT JOIN supply_details spr ON spr.total_avail_qty > 0
WHERE spr.avg_supply_cost_per_qty IS NOT NULL
  AND ns.total_account_balance > (SELECT AVG(total_account_balance) FROM nation_stats)
  AND (cs.order_count >= 1 OR cs.total_spent IS NOT NULL)
ORDER BY ns.n_name, cs.total_spent DESC;
