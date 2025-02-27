WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL 
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey 
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
ranked_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
nation_stats AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    p.p_name,
    p.p_type,
    ns.n_name AS nation_name,
    n_stats.supplier_count,
    n_stats.total_acctbal,
    ro.total_revenue,
    rh.level AS supplier_level
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier_hierarchy rh ON ps.ps_suppkey = rh.s_suppkey
LEFT JOIN nation_stats n_stats ON rh.s_nationkey = n_stats.n_nationkey
LEFT JOIN ranked_orders ro ON ro.o_orderkey = (SELECT MAX(o.o_orderkey) 
                                                  FROM ranked_orders 
                                                  WHERE rn <= 5)
WHERE p.p_retailprice > 100.00
  AND (n_stats.supplier_count IS NOT NULL OR n_stats.total_acctbal > 0)
ORDER BY total_revenue DESC, p.p_name;
