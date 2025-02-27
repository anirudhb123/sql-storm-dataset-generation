WITH RECURSIVE HighValueSuppliers AS (
    SELECT s_suppkey, s_name, s_acctbal 
    FROM supplier 
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal 
    FROM supplier s
    JOIN HighValueSuppliers hvs ON s.s_acctbal > hvs.s_acctbal
),
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_mktsegment,
           SUM(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY o.o_orderkey) AS order_value
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
),
SupplierOrderCounts AS (
    SELECT ps.ps_suppkey, COUNT(DISTINCT fo.o_orderkey) AS order_count
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN FilteredOrders fo ON l.l_orderkey = fo.o_orderkey
    GROUP BY ps.ps_suppkey
),
FinalOutput AS (
    SELECT hvs.s_suppkey, hvs.s_name, COUNT(soc.order_count) AS total_orders, SUM(s.s_acctbal) AS total_acctbal
    FROM HighValueSuppliers hvs
    LEFT JOIN SupplierOrderCounts soc ON hvs.s_suppkey = soc.ps_suppkey
    GROUP BY hvs.s_suppkey, hvs.s_name
)
SELECT f.s_suppkey, f.s_name, f.total_orders, COALESCE(f.total_acctbal, 0) AS total_acctbal, 
       CASE 
           WHEN f.total_orders > 10 THEN 'High Volume'
           ELSE 'Low Volume'
       END AS order_volume_category
FROM FinalOutput f
ORDER BY f.total_orders DESC, f.s_name;
