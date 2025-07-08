
WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_nationkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
SupplierSummary AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderedLines AS (
    SELECT o.o_orderkey, l.l_partkey, l.l_quantity * l.l_extendedprice AS total_price,
           RANK() OVER (PARTITION BY o.o_orderkey ORDER BY l.l_discount DESC) AS rank_discount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
)
SELECT 
    r.r_name, 
    COALESCE(ns.total_supplycost, 0) AS total_supply_cost,
    SUM(ol.total_price) AS total_order_price,
    COUNT(DISTINCT ol.o_orderkey) AS total_orders,
    MAX(nh.level) AS nation_level
FROM region r
LEFT JOIN NationHierarchy nh ON r.r_regionkey = nh.n_regionkey
LEFT JOIN SupplierSummary ns ON nh.n_nationkey = ns.s_suppkey
LEFT JOIN OrderedLines ol ON ol.l_partkey = ns.s_suppkey
WHERE r.r_name LIKE 'North%'
GROUP BY r.r_name, ns.total_supplycost
HAVING SUM(ol.total_price) > 1000
ORDER BY total_order_price DESC;
