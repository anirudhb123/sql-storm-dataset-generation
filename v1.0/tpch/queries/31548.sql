
WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_partkey = s.s_suppkey
    WHERE s.s_acctbal > 1000 AND sh.level < 5
),
total_sales AS (
    SELECT c.c_custkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey
),
supplier_summary AS (
    SELECT s.s_suppkey,
           COUNT(ps.ps_partkey) AS part_count,
           AVG(ps.ps_supplycost) AS avg_supply_cost,
           SUM(l.l_extendedprice) AS total_value
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey
)
SELECT p.p_partkey,
       p.p_name,
       p.p_retailprice,
       COALESCE(ss.part_count, 0) AS total_parts,
       COALESCE(ss.avg_supply_cost, 0) AS average_supply_cost,
       COALESCE(ss.total_value, 0) AS total_value,
       CASE 
           WHEN ts.total_revenue IS NULL THEN 'No Sales'
           ELSE 'Sales Available'
       END AS sales_status,
       ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank,
       CASE 
           WHEN EXISTS (SELECT 1 FROM supplier_hierarchy sh WHERE sh.s_nationkey = s.s_nationkey) 
           THEN 'In Supply Chain'
           ELSE 'Out of Supply Chain'
       END AS supply_chain_status
FROM part p
LEFT JOIN supplier_summary ss ON p.p_partkey = ss.s_suppkey
LEFT JOIN total_sales ts ON ts.c_custkey = (SELECT c.c_custkey FROM customer c ORDER BY c.c_custkey LIMIT 1)
LEFT JOIN supplier s ON ss.s_suppkey = s.s_suppkey
WHERE p.p_retailprice > 0
AND (ss.part_count IS NOT NULL OR ts.total_revenue IS NOT NULL)
ORDER BY p.p_partkey;
