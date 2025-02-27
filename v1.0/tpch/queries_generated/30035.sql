WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey 
    WHERE s.s_acctbal > 1000 AND sh.level < 5
), OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, o.o_orderdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_orderdate
), RegionAggregates AS (
    SELECT r.r_name, COUNT(n.n_nationkey) AS nation_count, SUM(c.c_acctbal) AS total_customer_balance
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY r.r_name
)
SELECT 
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    p.p_container,
    COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity END), 0) AS total_returned_quantity,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) > 0 THEN AVG(os.total_revenue) 
        ELSE 0 
    END AS average_revenue,
    ra.nation_count,
    ra.total_customer_balance
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN OrderSummary os ON o.o_orderkey = os.o_orderkey
LEFT JOIN RegionAggregates ra ON ra.nation_count IS NOT NULL
WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
AND (p.p_size BETWEEN 10 AND 100 OR p.p_type LIKE '%brass%')
GROUP BY p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_container, ra.nation_count, ra.total_customer_balance
ORDER BY total_returned_quantity DESC, average_revenue DESC
LIMIT 100;
