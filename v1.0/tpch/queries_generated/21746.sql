WITH RECURSIVE cte_supplier_balance AS (
    SELECT s_suppkey, s_name, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal + c.s_acctbal, c.level + 1
    FROM supplier s
    JOIN cte_supplier_balance c ON s.s_suppkey = c.s_suppkey
    WHERE c.level < 5
),

ordered_data AS (
    SELECT o.o_orderkey, 
           o.o_custkey, 
           o.o_orderstatus,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(l.l_orderkey) AS item_count,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderstatus
),

filtered_orders AS (
    SELECT o.*, 
           CASE WHEN total_revenue > 10000 THEN 'High' 
                WHEN total_revenue BETWEEN 5000 AND 10000 THEN 'Medium' 
                ELSE 'Low' END AS revenue_category
    FROM ordered_data o
    WHERE revenue_rank <= 10
    AND o.o_orderstatus IN ('F', 'O')
),

nation_customer AS (
    SELECT c.c_custkey, 
           c.c_name, 
           n.n_name AS nation_name
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
)

SELECT d.o_orderkey, 
       d.o_orderstatus, 
       nf.c_name AS customer_name, 
       nf.nation_name, 
       d.total_revenue,
       d.revenue_category,
       COALESCE(SUM(ps.ps_supplycost), 0) AS total_supply_cost,
       CASE WHEN d.item_count <> 0 THEN (SUM(ps.ps_supplycost) / d.item_count) ELSE NULL END AS avg_supply_cost_per_item
FROM filtered_orders d
LEFT JOIN partsupp ps ON d.o_orderkey = ps.ps_partkey
JOIN nation_customer nf ON d.o_custkey = nf.c_custkey
GROUP BY d.o_orderkey, d.o_orderstatus, nf.c_name, nf.nation_name, d.total_revenue, d.revenue_category
HAVING d.total_revenue > 5000 OR (d.total_revenue IS NULL AND d.o_orderstatus = 'O')
ORDER BY d.total_revenue DESC, d.o_orderkey;
