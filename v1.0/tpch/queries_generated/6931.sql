WITH SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerStats AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
OrderLineStats AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM lineitem l
    GROUP BY l.l_orderkey
),
RegionStats AS (
    SELECT r.r_regionkey, r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT 
    ss.s_name, 
    cs.c_name, 
    os.total_line_value, 
    rs.r_name, 
    rs.nation_count
FROM SupplierStats ss
JOIN CustomerStats cs ON ss.total_supply_cost > 10000
JOIN OrderLineStats os ON os.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'F')
JOIN RegionStats rs ON rs.nation_count > 2
ORDER BY ss.total_supply_cost DESC, cs.total_order_value DESC;
