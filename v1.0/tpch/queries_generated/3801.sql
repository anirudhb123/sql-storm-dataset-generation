WITH RankedOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           o.o_orderstatus,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
),
SupplierStats AS (
    SELECT ps.ps_partkey,
           s.s_nationkey,
           COUNT(s.s_suppkey) AS supplier_count,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_nationkey
),
LineItemStats AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
           COUNT(l.l_linenumber) AS line_count
    FROM lineitem l
    WHERE l.l_shipdate <= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY l.l_orderkey
),
TotalSales AS (
    SELECT c.c_mktsegment,
           SUM(l.revenue) AS total_revenue,
           COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM LineItemStats l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    GROUP BY c.c_mktsegment
)
SELECT r.r_name,
       COALESCE(SUM(ts.total_revenue), 0) AS market_revenue,
       AVG(ss.total_supply_cost) AS avg_supply_cost,
       MAX(ss.supplier_count) AS max_suppliers
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierStats ss ON n.n_nationkey = ss.s_nationkey
LEFT JOIN TotalSales ts ON n.n_nationkey = ts.c_mktsegment
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name
HAVING SUM(ts.total_revenue) IS NOT NULL OR AVG(ss.total_supply_cost) > 1000
ORDER BY market_revenue DESC, r.r_name ASC;
