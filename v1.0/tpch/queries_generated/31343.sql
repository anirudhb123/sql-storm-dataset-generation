WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, n_comment, 0 AS level
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, n.n_comment, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_nationkey = nh.n_regionkey
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost, 
           COUNT(DISTINCT ps.ps_partkey) AS parts_supplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > 2000.00
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, ss.total_cost, ss.parts_supplied,
           RANK() OVER (ORDER BY ss.total_cost DESC) AS rank
    FROM SupplierStats ss
    JOIN supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE ss.parts_supplied > 5
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT n.n_name, ts.s_name, od.total_revenue
FROM NationHierarchy n
LEFT JOIN TopSuppliers ts ON n.n_nationkey = ts.s_suppkey
LEFT JOIN OrderDetails od ON od.o_orderkey = ts.s_suppkey
WHERE (n.n_comment IS NOT NULL OR ts.total_cost > 50000)
  AND (od.total_revenue IS NULL OR od.total_revenue > 10000)
ORDER BY n.n_name, ts.total_cost DESC
LIMIT 10;
