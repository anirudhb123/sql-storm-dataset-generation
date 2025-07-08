WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON sh.s_nationkey = s.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
top_supp AS (
    SELECT s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE ps.ps_availqty > (
        SELECT AVG(ps_availqty) FROM partsupp
    )
    GROUP BY s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 50000
),
sales_summary AS (
    SELECT c.c_nationkey, SUM(o.o_totalprice) AS total_sales,
           COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_nationkey
),
final_report AS (
    SELECT n.n_name AS nation_name, ss.total_sales, ss.total_orders,
           COALESCE(th.total_supply_cost, 0) AS total_supply_cost
    FROM nation n
    LEFT JOIN sales_summary ss ON n.n_nationkey = ss.c_nationkey
    LEFT JOIN top_supp th ON th.s_name LIKE '%' || n.n_name || '%'
)

SELECT fr.nation_name, fr.total_sales, fr.total_orders, fr.total_supply_cost,
       CASE WHEN fr.total_orders > 10 THEN 'High Activity' ELSE 'Low Activity' END AS activity_level,
       ROW_NUMBER() OVER (ORDER BY fr.total_sales DESC) AS sales_rank
FROM final_report fr
WHERE fr.total_sales IS NOT NULL
ORDER BY fr.total_supply_cost DESC;
