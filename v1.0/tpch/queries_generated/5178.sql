WITH RegionSupplier AS (
    SELECT n.n_name AS nation_name, r.r_name AS region_name, s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_name, r.r_name, s.s_suppkey
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY o.o_orderkey, o.o_custkey
),
CombinedData AS (
    SELECT rs.nation_name, rs.region_name, od.o_orderkey, od.total_order_value, COUNT(DISTINCT rs.s_suppkey) AS supplier_count
    FROM RegionSupplier rs
    JOIN OrderDetails od ON rs.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey
        WHERE l.l_orderkey = od.o_orderkey
    )
    GROUP BY rs.nation_name, rs.region_name, od.o_orderkey, od.total_order_value
)
SELECT cd.nation_name, cd.region_name, COUNT(cd.o_orderkey) AS order_count, AVG(cd.total_order_value) AS average_order_value, SUM(cd.supplier_count) AS total_suppliers
FROM CombinedData cd
GROUP BY cd.nation_name, cd.region_name
ORDER BY cd.region_name, cd.nation_name;
