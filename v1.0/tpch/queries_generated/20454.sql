WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, s_comment,
           1 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL AND LENGTH(s_comment) > 5
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment,
           sh.level + 1
    FROM supplier s
    INNER JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.s_acctbal
)
, lineitem_totals AS (
    SELECT l_orderkey, SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
    FROM lineitem
    GROUP BY l_orderkey
)
, order_frequencies AS (
    SELECT o.o_orderkey, COUNT(l.l_orderkey) AS freq
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY o.o_orderkey
)
SELECT s.s_name AS supplier_name,
       COALESCE(r.r_name, 'UNKNOWN') AS region_name,
       SUM(CASE WHEN sh.level <= 3 THEN s.s_acctbal ELSE 0 END) AS total_account_balance,
       AVG(ot.freq) AS avg_order_freq,
       STRING_AGG(DISTINCT p.p_name) AS part_names,
       COUNT(DISTINCT c.c_custkey) FILTER (WHERE c.c_acctbal > 0 AND c.c_mktsegment = 'BUILD') AS positive_customers
FROM supplier s
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN customer c ON s.s_nationkey = c.c_nationkey
JOIN lineitem_totals lt ON lt.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O')
JOIN order_frequencies ot ON ot.o_orderkey = lt.l_orderkey
LEFT JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey
GROUP BY s.s_name, r.r_name
HAVING SUM(ps.ps_availqty) IS NOT NULL 
   AND AVG(lt.total_revenue) > 1000
   AND COALESCE(MIN(s.s_acctbal), 0) < 500
ORDER BY total_account_balance DESC NULLS LAST, avg_order_freq DESC;
