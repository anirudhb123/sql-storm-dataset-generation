WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.level * 1000
), RegionStats AS (
    SELECT r.r_regionkey, r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
), OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(*) OVER (PARTITION BY o.o_orderkey) AS line_item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_returnflag = 'N'
    GROUP BY o.o_orderkey
), SupplierRevenue AS (
    SELECT ps.ps_suppkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_revenue,
           COUNT(l.l_orderkey) AS order_count
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_suppkey
)
SELECT 
    r.r_name AS region_name,
    COALESCE(SUM(sr.supplier_revenue), 0) AS total_supplier_revenue,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    AVG(c.c_acctbal) AS average_acctbal,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    COUNT(DISTINCT o.o_orderkey) FILTER (WHERE o.o_orderstatus = 'O') AS total_open_orders
FROM RegionStats r
LEFT JOIN SupplierHierarchy s ON s.s_nationkey IN (
    SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey)
LEFT JOIN Customer c ON c.c_nationkey = s.s_nationkey
LEFT JOIN OrderSummary o ON o.o_orderkey IN (
    SELECT o.o_orderkey 
    FROM orders o 
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipmode = 'AIR'
)
LEFT JOIN SupplierRevenue sr ON sr.ps_suppkey = s.s_suppkey
GROUP BY r.r_name
ORDER BY total_supplier_revenue DESC, average_acctbal DESC
LIMIT 10;
