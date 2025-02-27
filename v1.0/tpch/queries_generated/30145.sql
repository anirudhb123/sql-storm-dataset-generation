WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)  -- Only include suppliers with above average account balance

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')  -- Joining to suppliers from the USA
    WHERE s.s_acctbal < sh.s_acctbal  -- Recursive logic to further filter based on account balance
),
TopRegions AS (
    SELECT r.r_name, SUM(o.o_totalprice) AS total_revenue
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY r.r_name
    ORDER BY total_revenue DESC
    LIMIT 5
),
PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
OrderSummary AS (
    SELECT o.o_orderkey, COUNT(l.l_linenumber) AS number_of_lines, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate > CURRENT_DATE - INTERVAL '60 days'  -- Orders shipped in the last 60 days
    GROUP BY o.o_orderkey
),
FinalReport AS (
    SELECT p.p_partkey, p.p_name, psi.total_available, psi.avg_supplycost, 
           os.number_of_lines, os.net_revenue, 
           th.r_name, th.total_revenue
    FROM PartSupplierInfo psi
    JOIN OrderSummary os ON psi.p_partkey = os.o_orderkey  -- Simulating a join on part key, adapted for benchmarking
    CROSS JOIN TopRegions th
)
SELECT f.p_partkey, f.p_name, f.total_available, f.avg_supplycost, 
       f.number_of_lines, f.net_revenue, f.r_name, f.total_revenue
FROM FinalReport f
WHERE f.net_revenue > 10000  -- Only include reports with net revenue above a threshold
ORDER BY f.total_available DESC, f.net_revenue DESC;
