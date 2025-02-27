WITH TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_supply_cost DESC
    LIMIT 10
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
    HAVING total_value > 50000
),
SupplierRegion AS (
    SELECT n.n_name AS nation_name, r.r_name AS region_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_name, r.r_name
)
SELECT tr.nation_name, tr.region_name, tr.supplier_count, toh.o_orderkey, toh.total_value, ts.total_supply_cost
FROM SupplierRegion tr
JOIN HighValueOrders toh ON toh.o_custkey IN (SELECT c.c_custkey FROM customer c 
                                              WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = tr.nation_name))
JOIN TopSuppliers ts ON ts.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps 
                                          WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p
                                                                  WHERE p.p_brand = 'Brand#23'))
ORDER BY ts.total_supply_cost DESC, toh.total_value DESC;
