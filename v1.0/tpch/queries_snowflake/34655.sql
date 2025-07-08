WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, s_comment, 0 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) AND sh.level < 5
),
AvgLineItemPrice AS (
    SELECT l_orderkey, AVG(l_extendedprice) AS avg_price
    FROM lineitem
    WHERE l_discount BETWEEN 0.05 AND 0.10
    GROUP BY l_orderkey
),
NationStats AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
           SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_totalprice
    FROM orders o 
    WHERE o.o_orderstatus = 'O' AND o.o_totalprice > 1000
),
OrderMetrics AS (
    SELECT fo.o_orderkey, fo.o_totalprice, 
           COALESCE(AVG(al.avg_price), 0) AS avg_lineitem_price
    FROM FilteredOrders fo
    LEFT JOIN AvgLineItemPrice al ON fo.o_orderkey = al.l_orderkey
    GROUP BY fo.o_orderkey, fo.o_totalprice
)
SELECT ns.n_name, 
       ns.supplier_count, 
       ns.total_acctbal, 
       SUM(om.o_totalprice) AS total_order_value, 
       COUNT(DISTINCT om.o_orderkey) AS total_orders 
FROM NationStats ns
LEFT JOIN OrderMetrics om ON ns.supplier_count > 0
GROUP BY ns.n_name, ns.supplier_count, ns.total_acctbal
HAVING AVG(ns.total_acctbal) < 5000
ORDER BY total_order_value DESC;
