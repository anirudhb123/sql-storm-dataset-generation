WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           CAST(s.s_name AS VARCHAR(100)) AS hierarchy_path
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           CONCAT(sh.hierarchy_path, ' > ', s.s_name)
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
),
NationRevenue AS (
    SELECT n.n_nationkey, n.n_name, SUM(os.total_revenue) AS nation_revenue
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN OrderSummary os ON os.o_orderkey = o.o_orderkey
    GROUP BY n.n_nationkey, n.n_name
),
RankedNationRevenue AS (
    SELECT nr.n_nationkey, nr.n_name, nr.nation_revenue,
           RANK() OVER (ORDER BY nr.nation_revenue DESC) AS revenue_rank
    FROM NationRevenue nr
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost, 
           (SELECT COUNT(DISTINCT l.l_orderkey) 
            FROM lineitem l 
            WHERE l.l_partkey = p.p_partkey) AS order_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 10
),
SupplierRevenueComparison AS (
    SELECT sh.s_name, SUM(pr.ps_supplycost) AS total_supply_cost,
           AVG(pr.ps_supplycost) AS avg_supply_cost
    FROM SupplierHierarchy sh
    JOIN PartSupplier pr ON sh.s_suppkey = pr.ps_partkey
    GROUP BY sh.s_name
)
SELECT n.n_name, nr.nation_revenue, r.revenue_rank, sr.s_name, sr.total_supply_cost
FROM RankedNationRevenue r
FULL OUTER JOIN NationRevenue nr ON r.n_nationkey = nr.n_nationkey
FULL OUTER JOIN SupplierRevenueComparison sr ON r.n_nationkey = sr.total_supply_cost
WHERE r.revenue_rank <= 5 AND sr.avg_supply_cost IS NOT NULL
ORDER BY nr.nation_revenue DESC, sr.total_supply_cost ASC;
