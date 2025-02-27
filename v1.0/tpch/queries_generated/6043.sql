WITH RankedSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.n_nationkey
),
TopSuppliers AS (
    SELECT r.r_name, rs.s_suppkey, rs.s_name, rs.total_supply_cost
    FROM RankedSuppliers rs
    JOIN nation n ON rs.n_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE rs.rank <= 5
),
OrderStatistics AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT ts.r_name AS region_name,
       ts.s_name AS supplier_name,
       COUNT(os.o_orderkey) AS total_orders,
       SUM(os.total_revenue) AS total_revenue,
       AVG(os.total_revenue) AS avg_revenue_per_order
FROM TopSuppliers ts
LEFT JOIN OrderStatistics os ON ts.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'Brand#23'))
GROUP BY ts.r_name, ts.s_name
ORDER BY ts.r_name, total_revenue DESC;
