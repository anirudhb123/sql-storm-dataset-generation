WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    INNER JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
), SupplierParts AS (
    SELECT ps.ps_partkey, s.s_name, SUM(ps.ps_availqty) AS total_avail_qty, AVG(s.s_acctbal) AS avg_acct_bal
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_name
), LineItemAnalysis AS (
    SELECT l.l_orderkey, 
           COUNT(*) AS total_items, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_shipdate DESC) AS rn
    FROM lineitem l
    WHERE l.l_shipdate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY l.l_orderkey
), CustomerInfo AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_mktsegment, 
           RANK() OVER (ORDER BY c.c_acctbal DESC) AS acct_rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
)
SELECT n.n_name, 
       sp.s_name, 
       sp.total_avail_qty, 
       la.total_items, 
       la.total_revenue, 
       ci.c_name, 
       ci.acct_rank,
       CASE 
           WHEN la.total_revenue > 10000 THEN 'High'
           WHEN la.total_revenue BETWEEN 5000 AND 10000 THEN 'Medium'
           ELSE 'Low' 
       END AS revenue_category
FROM NationHierarchy n
LEFT JOIN SupplierParts sp ON n.n_nationkey = sp.ps_partkey
LEFT JOIN LineItemAnalysis la ON la.l_orderkey = sp.ps_partkey
JOIN CustomerInfo ci ON ci.c_custkey = la.l_orderkey
WHERE ci.acct_rank <= 10 AND la.total_items > 1
ORDER BY n.n_name, sp.total_avail_qty DESC, la.total_revenue DESC;
