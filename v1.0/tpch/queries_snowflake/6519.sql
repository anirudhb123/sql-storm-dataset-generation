WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), 
HighCostSuppliers AS (
    SELECT s.s_suppkey, s.s_name, total_cost
    FROM RankedSuppliers s
    WHERE total_cost > (SELECT AVG(total_cost) FROM RankedSuppliers)
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
    GROUP BY c.c_custkey, c.c_name
    ORDER BY total_spent DESC
    LIMIT 5
)
SELECT 
    ns.n_name AS nation_name,
    COUNT(DISTINCT hs.s_suppkey) AS supplier_count,
    SUM(tc.total_spent) AS total_revenue
FROM nation ns
JOIN HighCostSuppliers hs ON ns.n_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
JOIN TopCustomers tc ON tc.c_custkey IN (SELECT DISTINCT o.o_custkey FROM orders o JOIN lineitem l ON o.o_orderkey = l.l_orderkey WHERE l.l_suppkey = hs.s_suppkey)
GROUP BY ns.n_name
HAVING COUNT(DISTINCT hs.s_suppkey) > 0
ORDER BY total_revenue DESC;