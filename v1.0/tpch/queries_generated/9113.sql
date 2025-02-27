WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_mktsegment,
           RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
),
TopSellingParts AS (
    SELECT ps.ps_partkey, SUM(l.l_quantity) AS total_quantity, SUM(l.l_extendedprice) AS total_revenue
    FROM lineitem l
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    GROUP BY ps.ps_partkey
    HAVING SUM(l.l_quantity) > 100
),
SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS supplier_nation
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > 50000
),
FinalReport AS (
    SELECT r.r_name AS region_name,
           COUNT(DISTINCT o.o_orderkey) AS total_orders,
           SUM(ts.total_revenue) AS total_revenue,
           COUNT(DISTINCT si.s_suppkey) AS total_suppliers
    FROM RankedOrders ro
    JOIN region r ON ro.o_orderkey % 5 = r.r_regionkey
    JOIN TopSellingParts ts ON ro.o_orderkey % 100 = ts.ps_partkey
    JOIN SupplierInfo si ON ts.ps_partkey % 10 = si.s_suppkey
    GROUP BY r.r_name
)
SELECT region_name, total_orders, total_revenue, total_suppliers
FROM FinalReport
ORDER BY total_revenue DESC, total_orders DESC;
