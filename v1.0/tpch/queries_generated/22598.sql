WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal AND sh.level < 5
),
PartProfit AS (
    SELECT ps.ps_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_profit
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_partkey
),
NationRegion AS (
    SELECT n.n_nationkey, r.r_name
    FROM nation n
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(np.r_name, 'Unknown Region') AS region_name,
    COALESCE(SUM(CASE WHEN l.l_discount > 0.2 THEN l.l_extendedprice * (1 - l.l_discount) END), 0) AS discounted_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT s.s_name) FILTER (WHERE s.s_acctbal > 0) AS active_suppliers,
    SUM(pp.total_profit) AS total_profit
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
LEFT JOIN NationRegion np ON sh.s_nationkey = np.n_nationkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE p.p_size BETWEEN 10 AND 30
AND p.p_retailprice IS NOT NULL
GROUP BY p.p_partkey, p.p_name, np.r_name
ORDER BY total_orders DESC, total_profit DESC
FETCH FIRST 10 ROWS ONLY;
