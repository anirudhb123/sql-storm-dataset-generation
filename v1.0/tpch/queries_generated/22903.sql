WITH ranked_orders AS (
    SELECT o.o_orderkey, 
           o.o_custkey, 
           o.o_orderdate, 
           o.o_totalprice, 
           ROW_NUMBER() OVER(PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01' 
      AND o.o_orderstatus IN ('O', 'F')
),
high_value_orders AS (
    SELECT ro.o_orderkey,
           ro.o_custkey,
           ro.o_totalprice,
           CASE 
               WHEN ro.o_totalprice IS NULL THEN 'No Price' 
               WHEN ro.o_totalprice > 1000 THEN 'High Value' 
               ELSE 'Standard' 
           END AS order_type
    FROM ranked_orders ro
    WHERE ro.order_rank <= 10
),
supplier_part_summary AS (
    SELECT ps.ps_partkey, 
           SUM(ps.ps_availqty) AS total_avail_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
bubble_joined_orders AS (
    SELECT ho.o_orderkey,
           ho.o_totalprice,
           sp.ps_partkey,
           sp.total_avail_qty,
           sp.avg_supply_cost
    FROM high_value_orders ho
    LEFT JOIN supplier_part_summary sp ON ho.o_custkey = sp.ps_partkey
    WHERE ho.o_totalprice * COALESCE(sp.avg_supply_cost, 1) > 500000
),
sales_analysis AS (
    SELECT CASE 
               WHEN l.l_returnflag = 'R' THEN 'Returned' 
               ELSE 'Completed' 
           END AS order_status,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY l.l_returnflag
),
final_report AS (
    SELECT bjo.o_orderkey,
           bjo.o_totalprice,
           sa.revenue,
           (bjo.total_avail_qty * COALESCE(sa.revenue, 0)) AS weighted_revenue
    FROM bubble_joined_orders bjo
    LEFT JOIN sales_analysis sa ON bjo.o_orderkey = sa.order_status
)
SELECT fr.o_orderkey,
       fr.o_totalprice,
       fr.revenue,
       CASE 
           WHEN fr.weighted_revenue IS NULL THEN 'No Revenue Impact'
           ELSE 'Revenue Impact' 
       END AS revenue_impact_status
FROM final_report fr
WHERE fr.weighted_revenue > 0
ORDER BY fr.o_totalprice DESC, fr.weighted_revenue ASC;
