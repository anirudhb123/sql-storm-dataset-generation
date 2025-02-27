WITH RECURSIVE region_hierarchy AS (
    SELECT r_regionkey, r_name, 1 AS level
    FROM region
    WHERE r_regionkey = 1

    UNION ALL

    SELECT r.r_regionkey, r.r_name, rh.level + 1
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN region_hierarchy rh ON rh.r_regionkey = n.n_nationkey
),
supplier_aggregation AS (
    SELECT s.s_nationkey, COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
           SUM(s.s_acctbal) AS total_acctbal
    FROM supplier s
    GROUP BY s.s_nationkey
),
customer_order_summary AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent,
           COUNT(DISTINCT o.o_orderkey) AS num_orders,
           RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS spend_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_nationkey
)
SELECT rh.r_name,
       COALESCE(cos.total_spent, 0) AS total_spent,
       COALESCE(cos.num_orders, 0) AS num_orders,
       sa.total_suppliers,
       sa.total_acctbal
FROM region_hierarchy rh
LEFT JOIN customer_order_summary cos ON rh.r_regionkey = cos.c_custkey
LEFT JOIN supplier_aggregation sa ON sa.s_nationkey = rh.r_regionkey
WHERE (cos.total_spent > (SELECT AVG(total_spent) FROM customer_order_summary) OR cos.total_spent IS NULL)
  AND (sa.total_suppliers IS NOT NULL OR sa.total_acctbal > 0)
ORDER BY rh.level, total_spent DESC NULLS LAST;
