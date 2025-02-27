WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n 
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    WHERE s.s_acctbal > 1000.00
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS recent_order_rank
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
)
SELECT 
    p.p_name AS part_name,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_return_qty,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    MAX(s.s_acctbal) AS max_supplier_acctbal,
    COUNT(DISTINCT c.c_custkey) FILTER (WHERE c.c_acctbal IS NOT NULL) AS total_customers
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN RecentOrders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN customer c ON o.o_custkey = c.c_custkey
WHERE p.p_retailprice > 50.00
GROUP BY p.p_name
HAVING SUM(l.l_quantity) > 0
ORDER BY total_orders DESC, part_name ASC;
