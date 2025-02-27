WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT sp.s_suppkey, sp.s_name, sp.s_acctbal, sh.level + 1
    FROM supplier sp
    JOIN SupplierHierarchy sh ON sp.s_acctbal > sh.s_acctbal
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice
    FROM part p
    WHERE p.p_size > 10 AND p.p_retailprice < 100.00
),
SupplierRevenue AS (
    SELECT s.s_suppkey, s.s_name, SUM(l.l_extendedprice) AS total_sales
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_name, sr.total_sales
    FROM supplier s
    JOIN SupplierRevenue sr ON s.s_suppkey = sr.s_suppkey
    WHERE sr.total_sales > (SELECT AVG(total_sales) FROM SupplierRevenue)
),
RegionStats AS (
    SELECT n.n_nationkey, r.r_name, COUNT(DISTINCT o.o_orderkey) AS total_orders,
           AVG(od.total_revenue) AS avg_order_value
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN OrderDetails od ON o.o_orderkey = od.o_orderkey
    GROUP BY n.n_nationkey, r.r_name
)
SELECT rh.level, ft.p_partkey, ft.p_name, rs.r_name, rs.total_orders, rs.avg_order_value, ts.s_name
FROM SupplierHierarchy rh
JOIN FilteredParts ft ON ft.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost < 50)
JOIN RegionStats rs ON rs.total_orders > 10
JOIN TopSuppliers ts ON ts.s_name IS NOT NULL
ORDER BY rh.level DESC, rs.avg_order_value DESC;
