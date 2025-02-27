WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_orderdate, 0 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderstatus, o.o_orderdate, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_orderkey
    WHERE oh.level < 5
),
PartSupplierDetails AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, 
           SUM(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS discounted_revenue,
           SUM(ps.ps_availqty) AS total_availqty
    FROM partsupp ps
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
NationStats AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           AVG(s.s_acctbal) AS avg_acctbal,
           STRING_AGG(DISTINCT s.s_comment) AS comments
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
)
SELECT 
    p.p_name, 
    p.p_mfgr,
    psd.discounted_revenue,
    ns.avg_acctbal,
    COALESCE(ns.supplier_count, 0) AS supplier_count,
    CASE 
        WHEN psd.discounted_revenue > 1000 THEN 'High Revenue'
        WHEN psd.discounted_revenue IS NULL THEN 'No Sales'
        ELSE 'Moderate Revenue'
    END AS revenue_category,
    COUNT(DISTINCT oh.o_orderkey) AS order_count
FROM part p
LEFT JOIN PartSupplierDetails psd ON p.p_partkey = psd.ps_partkey
LEFT JOIN NationStats ns ON ns.supplier_count >= 10
LEFT JOIN OrderHierarchy oh ON oh.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey)
GROUP BY p.p_name, p.p_mfgr, psd.discounted_revenue, ns.avg_acctbal
HAVING MAX(psd.total_availqty) > 25 OR MAX(psd.discounted_revenue) IS NULL
ORDER BY revenue_category DESC, AVG(ns.avg_acctbal) ASC
LIMIT 50;
