WITH RECURSIVE order_dates AS (
    SELECT o_orderdate, o_orderkey
    FROM orders
    WHERE o_orderstatus = 'O'
    UNION ALL
    SELECT DATEADD(day, 1, o_orderdate), o_orderkey
    FROM orders o
    JOIN order_dates od ON o.o_orderkey = od.o_orderkey
    WHERE o.o_orderdate < DATEADD(day, 30, od.o_orderdate)
),
part_supplier AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_brand, 
           SUM(ps.ps_supplycost) AS total_supplier_cost,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE p.p_size > 10
    GROUP BY p.p_partkey, p.p_name, p.p_brand
),
national_sales AS (
    SELECT n.n_name AS nation_name,
           COUNT(DISTINCT c.c_custkey) AS customer_count,
           SUM(o.o_totalprice) AS total_revenue
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_name
),
ranked_sales AS (
    SELECT nation_name, customer_count, total_revenue,
           RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM national_sales
),
part_stats AS (
    SELECT pss.p_partkey, 
           pss.total_supplier_cost, 
           rss.total_revenue,
           rss.revenue_rank,
           CASE 
               WHEN rss.revenue_rank IS NULL THEN 0
               ELSE pss.total_supplier_cost / NULLIF(rss.total_revenue, 0)
           END AS cost_to_revenue_ratio
    FROM part_supplier pss
    LEFT JOIN ranked_sales rss ON pss.p_brand = rss.nation_name
    WHERE pss.supplier_count > 2
)
SELECT p.p_name, 
       p.p_container, 
       ps.cost_to_revenue_ratio,
       ROW_NUMBER() OVER (PARTITION BY ps.cost_to_revenue_ratio IS NOT NULL ORDER BY ps.cost_to_revenue_ratio DESC) AS descending_rank
FROM part p
JOIN part_stats ps ON p.p_partkey = ps.p_partkey
WHERE ps.cost_to_revenue_ratio IS NOT NULL
  AND (ps.cost_to_revenue_ratio < 0.5 OR ps.cost_to_revenue_ratio > 2.0)
ORDER BY ps.cost_to_revenue_ratio DESC;
