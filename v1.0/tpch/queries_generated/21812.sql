WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal,
           CAST(s_name AS VARCHAR(100)) AS full_name,
           1 AS level
    FROM supplier
    WHERE s_acctbal > 5000
    UNION ALL
    SELECT sp.s_suppkey, sp.s_name, sp.s_nationkey, sp.s_acctbal,
           CONCAT(sh.full_name, ' -> ', sp.s_name),
           sh.level + 1
    FROM supplier sp
    JOIN SupplierHierarchy sh ON sp.s_nationkey = sh.s_nationkey
    WHERE sp.s_acctbal < sh.s_acctbal AND sh.level < 5
),
NationStats AS (
    SELECT n.n_name AS nation_name, 
           COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           AVG(s.s_acctbal) AS avg_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
PartDetails AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_retailprice IS NOT NULL AND p.p_size BETWEEN 5 AND 15
),
OrderSummary AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
           COUNT(DISTINCT l.l_linenumber) AS line_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
FilteredOrders AS (
    SELECT os.o_orderkey, os.net_revenue, os.line_count,
           CASE WHEN os.net_revenue > 10000 THEN 'High' 
                WHEN os.net_revenue BETWEEN 5000 AND 10000 THEN 'Medium' 
                ELSE 'Low' END AS revenue_category
    FROM OrderSummary os
)

SELECT nh.nation_name, 
       ps.supp_count,
       pd.p_name, 
       pd.p_retailprice,
       fo.net_revenue,
       fo.line_count,
       MAX(sh.level) AS max_hierarchy_level
FROM NationStats ns
LEFT JOIN FilteredOrders fo ON ns.supplier_count > 0
JOIN PartDetails pd ON pd.price_rank <= 3
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = ns.n_supplier_count 
WHERE ns.avg_acctbal IS NOT NULL
GROUP BY nh.nation_name, ps.supplier_count, pd.p_name, pd.p_retailprice, fo.net_revenue, fo.line_count
HAVING COUNT(DISTINCT pd.p_partkey) > 1
ORDER BY nh.nation_name, fo.net_revenue DESC, pd.p_retailprice ASC;
