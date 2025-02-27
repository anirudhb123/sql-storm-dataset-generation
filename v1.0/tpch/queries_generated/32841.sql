WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000

    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
AvgPartCost AS (
    SELECT ps.ps_partkey, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus
),
NationDetails AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)

SELECT 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type,
    COALESCE(AvgPartCost.avg_supplycost, 0) AS avg_supplycost,
    od.total_revenue, nd.supplier_count,
    CASE 
        WHEN nd.supplier_count > 10 THEN 'High'
        WHEN nd.supplier_count BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low' 
    END AS supplier_category
FROM part p
LEFT JOIN AvgPartCost ON p.p_partkey = AvgPartCost.ps_partkey
LEFT JOIN OrderDetails od ON od.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'F')
LEFT JOIN NationDetails nd ON p.p_brand = nd.n_nationkey
WHERE (p.p_retailprice IS NOT NULL AND p.p_retailprice > 0)
  AND EXISTS (SELECT 1 FROM SupplierHierarchy sh WHERE sh.s_nationkey = p.p_partkey AND sh.level < 3)
ORDER BY total_revenue DESC, p.p_partkey
LIMIT 100;
