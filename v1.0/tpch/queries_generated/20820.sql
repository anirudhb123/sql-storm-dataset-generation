WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (
        SELECT AVG(s2.s_acctbal) FROM supplier s2
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE sh.level < 3 AND s.s_acctbal IS NOT NULL
),
ranked_orders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS revenue_rank
    FROM orders o
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS net_revenue,
    COUNT(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN l.l_orderkey END) AS return_orders,
    (SELECT AVG(s.s_acctbal) FROM supplier s WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE '%land%')) AS average_supplier_balance,
    COUNT(DISTINCT c.c_custkey) AS distinct_customers
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN customer c ON o.o_custkey = c.c_custkey
LEFT JOIN supplier_hierarchy sh ON l.l_suppkey = sh.s_suppkey
WHERE p.p_size > 30 AND p.p_retailprice BETWEEN (
    SELECT MIN(p2.p_retailprice) FROM part p2 WHERE p2.p_size = p.p_size
) AND (
    SELECT MAX(p3.p_retailprice) FROM part p3 WHERE p3.p_size = p.p_size
) 
OR (sh.level IS NOT NULL AND sh.level = 2)
GROUP BY p.p_partkey, p.p_name, p.p_brand
HAVING net_revenue > (
    SELECT AVG(net_revenue) FROM (
        SELECT SUM(l2.l_extendedprice * (1 - l2.l_discount)) AS net_revenue
        FROM lineitem l2
        GROUP BY l2.l_partkey
    ) AS avg_revenue_subquery
) OR EXISTS (
    SELECT 1 FROM ranked_orders ro WHERE ro.revenue_rank = 1 AND ro.o_orderkey IN (SELECT o.orderkey FROM orders o WHERE o.o_orderstatus = 'F')
)
ORDER BY net_revenue DESC, return_orders DESC
LIMIT 100;
