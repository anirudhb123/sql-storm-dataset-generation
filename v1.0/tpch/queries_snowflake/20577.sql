WITH RECURSIVE supplier_rank AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           DENSE_RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
), aggregate_stats AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_supply_cost,
           COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM partsupp ps
    GROUP BY ps.ps_partkey
), recent_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= cast('1998-10-01' as date) - INTERVAL '30 days'
    GROUP BY o.o_orderkey, o.o_orderdate
), combined_data AS (
    SELECT DISTINCT p.p_partkey, p.p_name, p.p_brand,
           r.r_name AS region_name,
           coalesce(a.total_supply_cost, 0) AS total_supply_cost,
           coalesce(a.unique_suppliers, 0) AS unique_suppliers,
           coalesce(ro.total_value, 0) AS recent_order_value
    FROM part p
    LEFT JOIN aggregate_stats a ON p.p_partkey = a.ps_partkey
    LEFT JOIN nation n ON p.p_partkey % (SELECT COUNT(n.n_nationkey) FROM nation n) = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN recent_orders ro ON ro.o_orderkey = (SELECT MIN(o.o_orderkey)
                                                    FROM orders o 
                                                    WHERE o.o_orderdate = cast('1998-10-01' as date)
                                                    AND o.o_orderstatus = 'F')
)
SELECT cd.p_partkey, cd.p_name, cd.p_brand, cd.region_name,
       cd.total_supply_cost, cd.unique_suppliers, cd.recent_order_value,
       CASE 
           WHEN cd.recent_order_value > 10000 THEN 'High Value'
           ELSE 'Low Value'
       END AS order_value_category
FROM combined_data cd
WHERE cd.total_supply_cost IS NOT NULL
  AND EXISTS (
      SELECT 1 FROM supplier_rank sr 
      WHERE sr.s_acctbal > 100000
        AND sr.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = cd.p_partkey)
  )
ORDER BY cd.recent_order_value DESC
LIMIT 10;