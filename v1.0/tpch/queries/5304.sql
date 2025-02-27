WITH RegionSupplier AS (
    SELECT n.n_name AS nation_name, r.r_name AS region_name, s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_name, r.r_name, s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT c.c_nationkey, SUM(o.o_totalprice) AS total_order_value, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_nationkey
),
FinalBenchmark AS (
    SELECT rs.region_name, rs.nation_name, rs.s_name, rs.total_supply_cost, os.total_order_value, os.order_count
    FROM RegionSupplier rs
    LEFT JOIN OrderSummary os ON rs.nation_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = os.c_nationkey)
)
SELECT region_name, nation_name, s_name, total_supply_cost, total_order_value, order_count
FROM FinalBenchmark
WHERE total_supply_cost > 100000
ORDER BY total_supply_cost DESC, total_order_value DESC;
