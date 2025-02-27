WITH recursive supplier_summary AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), 
customer_summary AS (
    SELECT c.c_custkey, 
           COUNT(o.o_orderkey) AS total_orders,
           MAX(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice ELSE 0 END) AS highest_fulfilled_order
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
), 
percentile_orders AS (
    SELECT c.c_custkey,
           NTILE(100) OVER (ORDER BY total_orders DESC) AS order_percentile
    FROM customer_summary c
), 
part_details AS (
    SELECT p.p_partkey,
           p.p_name,
           p.p_brand,
           COUNT(*) AS supply_count,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
)
SELECT p.p_name,
       p.p_brand,
       COALESCE(ss.total_cost, 0) AS supplier_total_cost,
       cs.total_orders,
       cs.highest_fulfilled_order,
       po.order_percentile,
       pd.supply_count,
       pd.avg_supply_cost
FROM part_details pd
LEFT JOIN supplier_summary ss ON pd.supply_count > 10 AND pd.supply_count = ss.rn
LEFT JOIN customer_summary cs ON cs.total_orders > 5 AND cs.highest_fulfilled_order IS NOT NULL
JOIN percentile_orders po ON cs.c_custkey = po.c_custkey
WHERE (ss.total_cost IS NULL OR ss.total_cost > 1000.00)
  AND (pd.avg_supply_cost < 200.00 OR pd.avg_supply_cost IS NULL)
ORDER BY supplier_total_cost DESC, highest_fulfilled_order DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;
