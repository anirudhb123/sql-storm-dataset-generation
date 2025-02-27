WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_suppkey > sh.s_suppkey
),
AvgOrderPrice AS (
    SELECT o.o_orderkey, AVG(l.l_extendedprice) AS avg_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate > '2022-01-01'
    GROUP BY o.o_orderkey
),
TopNations AS (
    SELECT n.n_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_name
    ORDER BY total_supply_cost DESC
    LIMIT 5
)
SELECT 
    r.r_name,
    COALESCE(TH.total_supply_cost, 0) AS total_supply_cost,
    ROUND(AVG(OP.avg_price), 2) AS average_order_price,
    COUNT(DISTINCT SH.s_suppkey) AS supplier_count,
    CONCAT('Total Cost: ', COALESCE(TH.total_supply_cost, 0), ' | Avg Order Price: ', ROUND(AVG(OP.avg_price), 2)) AS report
FROM region r
LEFT JOIN TopNations TH ON r.r_name = TH.n_name
LEFT JOIN AvgOrderPrice OP ON OP.o_orderkey IN (SELECT o_orderkey FROM orders WHERE o_orderdate > '2022-01-01')
LEFT JOIN SupplierHierarchy SH ON SH.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = r.r_name LIMIT 1)
GROUP BY r.r_name, TH.total_supply_cost
ORDER BY r.r_name;
