WITH SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), OrderSummary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_revenue, COUNT(l.l_orderkey) AS lineitem_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY o.o_orderkey, o.o_custkey
), CustomerAnalysis AS (
    SELECT c.c_custkey, c.c_name, SUM(os.order_revenue) AS total_revenue, COUNT(os.o_orderkey) AS order_count
    FROM customer c
    JOIN OrderSummary os ON c.c_custkey = os.o_custkey
    GROUP BY c.c_custkey, c.c_name
), NationSuppliers AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
)
SELECT cs.c_custkey, cs.c_name, cs.total_revenue, cs.order_count, 
       ns.n_name AS supplier_nation, ns.supplier_count, 
       ss.total_supply_cost
FROM CustomerAnalysis cs
JOIN nation n ON cs.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
JOIN NationSuppliers ns ON n.n_name = ns.n_name
JOIN SupplierStats ss ON ns.supplier_count = ss.s_suppkey
ORDER BY cs.total_revenue DESC, cs.order_count DESC
LIMIT 100;