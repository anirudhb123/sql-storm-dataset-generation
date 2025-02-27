WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    INNER JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
SupplierSummary AS (
    SELECT s.s_nationkey, SUM(s.s_acctbal) AS total_acctbal
    FROM supplier s
    GROUP BY s.s_nationkey
),
PartSupplierStats AS (
    SELECT ps.ps_partkey, 
           AVG(ps.ps_supplycost) AS avg_supplycost,
           SUM(ps.ps_availqty) AS total_availqty,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
OrderLineItem AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
           COUNT(l.l_linenumber) AS line_count
    FROM lineitem l
    GROUP BY l.l_orderkey
),
FilteredOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           ol.net_revenue,
           CASE
               WHEN ol.line_count > 10 THEN 'High Volume'
               ELSE 'Low Volume'
           END AS order_type
    FROM orders o
    JOIN OrderLineItem ol ON o.o_orderkey = ol.l_orderkey
    WHERE o.o_orderstatus = 'O'
)
SELECT nh.n_name,
       COALESCE(sup.total_acctbal, 0) AS total_supplier_acctbal,
       p.ps_partkey,
       COALESCE(ps.avg_supplycost, 0) AS avg_supply_cost,
       COALESCE(fo.net_revenue, 0) AS total_net_revenue,
       fo.order_type
FROM NationHierarchy nh
LEFT JOIN SupplierSummary sup ON nh.n_nationkey = sup.s_nationkey
LEFT JOIN PartSupplierStats ps ON nh.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.ps_partkey))
LEFT JOIN FilteredOrders fo ON fo.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = ps.ps_partkey)
ORDER BY nh.level, nh.n_name, p.ps_partkey;
