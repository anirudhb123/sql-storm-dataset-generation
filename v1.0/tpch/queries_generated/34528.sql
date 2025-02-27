WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, CAST(s.s_name AS VARCHAR(100)) AS hierarchy_path
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s2.s_suppkey, s2.s_name, s2.s_acctbal, CAST(CONCAT(sh.hierarchy_path, ' -> ', s2.s_name) AS VARCHAR(100))
    FROM supplier s2
    JOIN SupplierHierarchy sh ON s2.s_nationkey = sh.s_suppkey
    WHERE s2.s_acctbal > 1000
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           DENSE_RANK() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
RegionInfo AS (
    SELECT r.r_regionkey, r.r_name, SUM(s.s_acctbal) AS total_account_balance
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name
),
PartSupplierAverage AS (
    SELECT ps.ps_partkey, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    ps.avg_supplycost,
    r.total_account_balance,
    od.total_revenue
FROM part p
LEFT JOIN PartSupplierAverage ps ON p.p_partkey = ps.ps_partkey
FULL OUTER JOIN RegionInfo r ON r.total_account_balance IS NOT NULL
LEFT JOIN OrderDetails od ON od.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O')
WHERE (ps.avg_supplycost > 200 OR r.total_account_balance IS NULL)
AND p.p_size BETWEEN 1 AND 50
ORDER BY p.p_retailprice DESC, total_revenue NULLS LAST
FETCH FIRST 100 ROWS ONLY;
