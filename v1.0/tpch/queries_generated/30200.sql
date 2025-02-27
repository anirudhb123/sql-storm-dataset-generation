WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, 
           1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, 
           sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_acctbal < sh.s_acctbal
    WHERE s.s_suppkey != sh.s_suppkey
),
order_summary AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           COUNT(l.l_orderkey) AS lineitem_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice
),
region_summary AS (
    SELECT r.r_regionkey, r.r_name, 
           COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT r.r_name, 
       COALESCE(SUM(os.total_revenue), 0) AS total_revenue, 
       COALESCE(SUM(sh.s_acctbal), 0) AS total_supplier_balance, 
       COUNT(DISTINCT c.c_custkey) AS customer_count
FROM region_summary r
LEFT JOIN supplier_hierarchy sh ON sh.s_acctbal IS NOT NULL
LEFT JOIN customer c ON c.c_nationkey IN (SELECT n.n_nationkey 
                                           FROM nation n 
                                           WHERE n.n_regionkey = r.r_regionkey)
LEFT JOIN order_summary os ON os.o_orderkey IN (SELECT o.o_orderkey 
                                                  FROM orders o 
                                                  WHERE o.o_custkey = c.c_custkey)
GROUP BY r.r_name
ORDER BY total_revenue DESC, total_supplier_balance ASC
LIMIT 10;
