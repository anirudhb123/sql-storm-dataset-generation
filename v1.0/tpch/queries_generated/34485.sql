WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_nationkey in (SELECT DISTINCT n_nationkey FROM supplier)
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_regionkey
),
AverageCost AS (
    SELECT ps_partkey, AVG(ps_supplycost) AS avg_supplycost
    FROM partsupp
    GROUP BY ps_partkey
),
OrderStatistics AS (
    SELECT o.o_orderstatus, COUNT(DISTINCT o.o_orderkey) AS total_orders,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           SUM(l.l_quantity) AS total_quantity
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= DATE '2023-01-01'
    GROUP BY o.o_orderstatus
),
SupplierStatistics AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
)
SELECT nh.n_name, 
       COALESCE(OS.total_orders, 0) AS total_orders,
       COALESCE(OS.total_revenue, 0) AS total_revenue,
       COALESCE(OS.total_quantity, 0) AS total_quantity,
       COALESCE(AC.avg_supplycost, 0) AS avg_supplycost,
       S.total_supplycost
FROM NationHierarchy nh
LEFT JOIN OrderStatistics OS ON nh.n_name = OS.o_orderstatus
LEFT JOIN AverageCost AC ON AC.ps_partkey = (SELECT ps.ps_partkey 
                                                FROM partsupp ps 
                                                WHERE ps.ps_supplycost = (SELECT MAX(ps_supplycost) 
                                                                           FROM partsupp))
                                                LIMIT 1)
LEFT JOIN SupplierStatistics S ON S.s_suppkey = (SELECT MIN(s.s_suppkey) 
                                                   FROM supplier s 
                                                   WHERE s.s_acctbal IS NOT NULL)
ORDER BY nh.level DESC, nh.n_name;
