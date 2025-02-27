WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, sh.s_acctbal * 0.75, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN supplier s ON sh.s_suppkey = s.s_suppkey
    WHERE sh.level < 5
),
average_prices AS (
    SELECT ps.ps_partkey, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
nation_supp_customers AS (
    SELECT n.n_name AS nation, COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
           SUM(c.c_acctbal) AS total_acctbal
    FROM nation n
    LEFT OUTER JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT OUTER JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_name
),
lineitem_summary AS (
    SELECT l.l_partkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS return_count
    FROM lineitem l
    GROUP BY l.l_partkey
)
SELECT nsc.nation, nsc.supplier_count, nsc.total_acctbal, 
       ls.total_revenue, 
       CASE 
           WHEN ls.return_count > 0 THEN 'Includes Returns' 
           ELSE 'No Returns' 
       END AS return_status,
       CASE 
           WHEN ap.avg_supplycost IS NOT NULL THEN ap.avg_supplycost 
           ELSE 'No Avg Cost' 
       END AS average_supply_cost,
       COUNT(DISTINCT sh.s_suppkey) AS hierarchical_supplier_count
FROM nation_supp_customers nsc
LEFT JOIN lineitem_summary ls ON nsc.nation = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = ls.l_partkey)
LEFT JOIN average_prices ap ON ls.l_partkey = ap.ps_partkey
LEFT JOIN supplier_hierarchy sh ON nsc.nation = (SELECT DISTINCT n.n_name FROM nation n JOIN supplier s ON n.n_nationkey = s.s_nationkey WHERE s.s_suppkey = sh.s_suppkey)
GROUP BY nsc.nation, nsc.supplier_count, nsc.total_acctbal, ls.total_revenue, ls.return_count, ap.avg_supplycost
ORDER BY nsc.total_acctbal DESC, ls.total_revenue DESC;
