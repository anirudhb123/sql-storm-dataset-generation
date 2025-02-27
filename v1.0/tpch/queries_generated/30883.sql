WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_suppkey = (SELECT MIN(s_suppkey) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, h.level + 1
    FROM supplier s
    JOIN SupplierHierarchy h ON s.n_nationkey = h.s_nationkey
    WHERE h.level < 5
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           RANK() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
),
OrderDetails AS (
    SELECT c.c_custkey, c.c_name, o.total_revenue, 
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.total_revenue DESC) AS revenue_rank
    FROM customer c
    JOIN RankedOrders o ON c.c_custkey = o.o_custkey
    WHERE o.total_revenue IS NOT NULL
),
NationSummary AS (
    SELECT n.n_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT s.s_suppkey) AS unique_suppliers
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_name
)
SELECT ns.n_name, os.c_name, os.total_revenue, os.revenue_rank, ns.total_supply_cost, ns.unique_suppliers
FROM NationSummary ns
FULL OUTER JOIN OrderDetails os ON ns.n_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = (SELECT DISTINCT c.c_nationkey FROM customer c WHERE c.c_custkey = os.c_custkey))
WHERE (os.revenue_rank <= 3 OR ns.unique_suppliers > 10)
ORDER BY ns.n_name, os.total_revenue DESC;
