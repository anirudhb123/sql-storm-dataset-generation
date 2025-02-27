WITH RECURSIVE nation_ranks AS (
    SELECT n.n_nationkey, n.n_name, n.n_regionkey,
           DENSE_RANK() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS acct_rank
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
),
supplier_part_aggregate AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail,
           MIN(s.s_acctbal) AS min_acctbal, MAX(s.s_acctbal) AS max_acctbal,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
)
SELECT DISTINCT r.r_name, 
                COALESCE(p.p_name, 'Unknown Part') AS part_name,
                sp.total_avail, 
                COALESCE(sp.supplier_count, 0) AS supplier_count,
                n.n_name AS nation_name,
                CASE WHEN sp.total_avail IS NULL THEN 'No Supply'
                     WHEN sp.total_avail > 1000 THEN 'Abundant Supply'
                     ELSE 'Limited Supply' END AS supply_status,
                ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY sp.total_avail DESC) AS supply_rank
FROM region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN supplier_part_aggregate sp ON sp.supplier_count > 1
LEFT JOIN part p ON p.p_partkey = sp.ps_partkey
WHERE n.n_nationkey IN (SELECT nr.n_nationkey FROM nation_ranks nr WHERE nr.acct_rank <= 3)
      AND (sp.total_avail IS NULL OR sp.total_avail < 500 OR sp.total_avail IS NOT NULL)
UNION ALL
SELECT 'Overall' AS r_name,
       NULL AS part_name,
       SUM(sp.total_avail) AS total_avail,
       COUNT(DISTINCT s.s_suppkey) AS supplier_count,
       NULL AS nation_name,
       'Aggregate Supply' AS supply_status,
       NULL AS supply_rank
FROM supplier_part_aggregate sp
JOIN supplier s ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps)
WHERE s.s_acctbal <> 0
GROUP BY r.r_name
ORDER BY r_name, total_avail DESC;
