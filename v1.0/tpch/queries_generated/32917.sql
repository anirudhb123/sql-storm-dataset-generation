WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        CASE WHEN s.s_acctbal IS NULL THEN 0 ELSE s.s_acctbal END AS s_acctbal,
        0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    
    UNION ALL

    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        CASE WHEN s.s_acctbal IS NULL THEN 0 ELSE s.s_acctbal END AS s_acctbal,
        sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey 
    WHERE sh.level < 3
),
NationPerformance AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(COALESCE(s.s_acctbal, 0)) AS total_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        COUNT(l.l_orderkey) AS lineitem_count,
        SUM(l.l_extendedprice) * (1 - SUM(l.l_discount)) AS net_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND o.o_totalprice > 10000
    GROUP BY o.o_orderkey
),
RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        RANK() OVER (ORDER BY SUM(l.l_extendedprice) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT 
    nh.n_name, 
    nh.supplier_count, 
    nh.total_acctbal, 
    ho.o_orderkey, 
    ho.lineitem_count,
    ho.net_order_value,
    CASE WHEN ro.order_rank IS NOT NULL THEN 'Ranked' ELSE 'Not Ranked' END AS order_status
FROM NationPerformance nh
LEFT JOIN HighValueOrders ho ON nh.supplier_count > 0
LEFT JOIN RankedOrders ro ON ho.o_orderkey = ro.o_orderkey
WHERE nh.total_acctbal > (SELECT AVG(total_acctbal) FROM NationPerformance)
ORDER BY nh.n_name, ho.net_order_value DESC;
