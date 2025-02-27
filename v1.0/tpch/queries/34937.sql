WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey AND s.s_suppkey <> sh.s_suppkey
),
total_cost AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * l.l_quantity) AS total_supply_cost
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_partkey
),
ranked_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, tc.total_supply_cost,
           RANK() OVER (ORDER BY (p.p_retailprice - COALESCE(tc.total_supply_cost, 0)) DESC) AS part_rank
    FROM part p
    LEFT JOIN total_cost tc ON p.p_partkey = tc.ps_partkey
),
nation_summary AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
)
SELECT ph.p_name, ph.p_retailprice, ph.total_supply_cost, ns.n_name AS nation_name,
       ns.supplier_count, ns.total_acctbal,
       CASE
           WHEN ph.total_supply_cost IS NULL THEN 'Not Supplied'
           ELSE 'Supplied'
       END AS supply_status
FROM ranked_parts ph
JOIN nation_summary ns ON ns.supplier_count > 10
WHERE ph.part_rank <= 5 OR (ph.p_retailprice IS NULL AND ph.total_supply_cost IS NOT NULL)
ORDER BY ns.total_acctbal DESC, ph.p_retailprice DESC;
