
WITH RECURSIVE RegionPromo AS (
    SELECT r.r_regionkey, r.r_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name
    HAVING COUNT(DISTINCT s.s_suppkey) > 0
),
PartRevenue AS (
    SELECT ps.ps_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_partkey
),
RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, COALESCE(pr.total_revenue, 0) AS total_revenue,
           SUM(CASE WHEN pr.total_revenue = 0 THEN 1 ELSE 0 END) OVER (PARTITION BY p.p_partkey) AS null_revenue_flag
    FROM part p
    LEFT JOIN PartRevenue pr ON p.p_partkey = pr.ps_partkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY SUM(ps.ps_supplycost) DESC
    LIMIT 5
)
SELECT r.r_name, rp.p_name, rp.total_revenue, ts.s_name AS top_supplier, 
       CASE WHEN rp.null_revenue_flag > 0 THEN 'No Revenue' ELSE 'Has Revenue' END AS revenue_status
FROM RegionPromo r
JOIN RankedParts rp ON rp.total_revenue > 0
LEFT JOIN TopSuppliers ts ON ts.supplier_rank = 1
WHERE r.r_regionkey IS NOT NULL
   OR EXISTS (SELECT 1 FROM customer c WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey) 
               AND c.c_acctbal IS NOT NULL AND c.c_mktsegment = 'BUILDING')
ORDER BY rp.total_revenue DESC, r.r_name;
