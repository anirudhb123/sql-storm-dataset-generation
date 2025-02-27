WITH RankedOrders AS (
    SELECT o_orderkey, o_custkey, o_totalprice, 
           RANK() OVER (PARTITION BY o_custkey ORDER BY o_totalprice DESC) AS rank_price,
           ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_orderdate DESC) AS row_orderdate
    FROM orders
),
FilteredLineItems AS (
    SELECT l_orderkey, SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
           AVG(l_quantity) AS avg_quantity
    FROM lineitem
    WHERE l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY l_orderkey
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, 
           (CASE WHEN ps.ps_supplycost IS NULL THEN 0 ELSE ps.ps_supplycost END) AS supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
NationInfo AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT n.n_name, ni.region_name, COUNT(DISTINCT c.c_custkey) AS customer_count,
       SUM(lo.total_revenue) AS total_line_revenue,
       SUM(CASE WHEN lo.total_revenue > 1000 THEN lo.total_revenue ELSE 0 END) AS revenue_high,
       AVG(lo.avg_quantity) AS avg_qty_per_order,
       string_agg(DISTINCT sd.s_name || ' - Cost: ' || sd.supply_cost::text, '; ') AS supplier_info
FROM FilteredLineItems lo
JOIN RankedOrders ro ON lo.l_orderkey = ro.o_orderkey
JOIN customer c ON c.c_custkey = ro.o_custkey
JOIN SupplierDetails sd ON sd.ps_partkey = (SELECT ps_partkey FROM partsupp ps WHERE ps.ps_supplycost = sd.supply_cost LIMIT 1)
JOIN NationInfo n ON n.n_nationkey = c.c_nationkey
WHERE ro.rank_price = 1 AND c.c_acctbal IS NOT NULL AND sd.s_name IS NOT NULL
GROUP BY n.n_name, ni.region_name
HAVING COUNT(DISTINCT c.c_custkey) > 5
ORDER BY total_line_revenue DESC NULLS LAST;
