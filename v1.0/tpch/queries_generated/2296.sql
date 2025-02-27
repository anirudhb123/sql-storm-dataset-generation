WITH SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_available, AVG(ps.ps_supplycost) AS avg_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_custkey
),
CustomerRegion AS (
    SELECT c.c_custkey, c.c_name, n.n_name AS nation_name
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
),
CombinedData AS (
    SELECT cr.c_custkey, cr.c_name, cr.nation_name, os.total_revenue, ss.total_available, ss.avg_cost,
           RANK() OVER (PARTITION BY cr.nation_name ORDER BY os.total_revenue DESC) AS revenue_rank
    FROM CustomerRegion cr
    LEFT JOIN OrderSummary os ON cr.c_custkey = os.o_custkey
    LEFT JOIN SupplierStats ss ON ss.total_available > 100
)
SELECT cd.c_custkey, cd.c_name, cd.nation_name, COALESCE(cd.total_revenue, 0) AS total_revenue,
       COALESCE(cd.total_available, 0) AS total_available, COALESCE(cd.avg_cost, 0) AS avg_cost, 
       cd.revenue_rank
FROM CombinedData cd
WHERE cd.revenue_rank <= 5 OR cd.total_available IS NULL
ORDER BY cd.nation_name, cd.total_revenue DESC;
