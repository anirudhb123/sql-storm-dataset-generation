WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal IS NOT NULL
)
SELECT 
    p.p_partkey,
    p.p_name,
    SUM(CASE 
            WHEN l.l_discount > 0.1 THEN l.l_extendedprice * (1 - l.l_discount)
            ELSE l.l_extendedprice 
        END) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MAX(CASE WHEN c.c_mktsegment = 'BUILDING' THEN c.c_acctbal ELSE NULL END) AS max_building_account_balance,
    AVG(NULLIF(ps.ps_supplycost, 0)) AS avg_supply_cost,
    r.r_name,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_quantity) DESC) AS quantity_rank
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN customer c ON o.o_custkey = c.c_custkey
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier_hierarchy sh ON ps.ps_suppkey = sh.s_suppkey
LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE l.l_shipmode IN (SELECT DISTINCT l_shipmode FROM lineitem WHERE l_returnflag = 'R') 
  AND l.l_shipdate < CURRENT_DATE
  AND (c.c_acctbal IS NOT NULL OR n.n_comment IS NOT NULL)
GROUP BY p.p_partkey, p.p_name, r.r_name
HAVING COUNT(DISTINCT o.o_orderkey) > 5
   AND SUM(l.l_quantity) >= ALL (SELECT AVG(l_inner.l_quantity) FROM lineitem l_inner WHERE l_inner.l_discount < 0.05)
ORDER BY total_revenue DESC;
