WITH RankedOrders AS (
    SELECT o.o_orderkey, 
           o.o_orderdate, 
           o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F') 
      AND o.o_totalprice IS NOT NULL
), 
SupplierParts AS (
    SELECT ps.ps_partkey, 
           ps.ps_suppkey, 
           SUM(ps.ps_availqty) AS total_avail_qty
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
    HAVING SUM(ps.ps_availqty) > 0
), 
OrderLineDetails AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_partkey) AS num_parts
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT r.r_name,
       COALESCE(SUM(ol.total_revenue), 0) AS revenue,
       COUNT(DISTINCT so.o_orderkey) AS order_count,
       MAX(CASE WHEN ro.rn = 1 THEN ro.o_orderdate END) AS max_order_date,
       COUNT(DISTINCT CASE WHEN ro.o_totalprice >= 500 THEN ro.o_orderkey END) AS high_value_orders
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierParts sp ON s.s_suppkey = sp.ps_suppkey
LEFT JOIN OrderLineDetails ol ON sp.ps_partkey = ol.l_orderkey
LEFT JOIN RankedOrders ro ON ol.l_orderkey = ro.o_orderkey 
WHERE (ro.o_orderkey IS NULL OR ro.o_orderdate >= '2023-01-01') 
  AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_comment IS NOT NULL)
GROUP BY r.r_name
HAVING SUM(ol.total_revenue) > (SELECT MAX(ps_supplycost) 
                                   FROM partsupp 
                                   WHERE ps_supplycost IS NOT NULL 
                                     AND ps_partkey IN (SELECT p_partkey 
                                                        FROM part 
                                                        WHERE p_size > 10))
ORDER BY revenue DESC, r.r_name;
