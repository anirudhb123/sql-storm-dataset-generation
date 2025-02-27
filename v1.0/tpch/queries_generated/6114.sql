WITH SupplierSummary AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey
),
LineItemAnalysis AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
),
CombinedAnalysis AS (
    SELECT ss.nation, cs.total_spent, la.total_revenue
    FROM SupplierSummary ss
    JOIN CustomerOrderSummary cs ON ss.nation = cs.total_spent -- Intentional odd join for testing performance implications
    JOIN LineItemAnalysis la ON la.l_orderkey = cs.c_custkey -- Another intentional odd join for complexity
)
SELECT nation, 
       AVG(total_spent) AS avg_spent,
       AVG(total_revenue) AS avg_revenue 
FROM CombinedAnalysis
GROUP BY nation
HAVING COUNT(*) > 5
ORDER BY avg_spent DESC, avg_revenue DESC
LIMIT 10;
