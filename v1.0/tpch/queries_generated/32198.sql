WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_suppkey <> sh.s_suppkey
),
top_part_suppliers AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_supplycost) AS total_supplycost
    FROM partsupp ps
    JOIN supplier_hierarchy sh ON ps.ps_suppkey = sh.s_suppkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey
), 
ranked_part_suppliers AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_type, top.total_supplycost,
           RANK() OVER (PARTITION BY p.p_partkey ORDER BY total_supplycost DESC) AS rank
    FROM part p
    JOIN top_part_suppliers top ON p.p_partkey = top.ps_partkey
)
SELECT r.r_name, np.n_name, rp.p_name, rp.total_supplycost AS supplycost
FROM ranked_part_suppliers rp
JOIN partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN nation np ON s.s_nationkey = np.n_nationkey
JOIN region r ON np.n_regionkey = r.r_regionkey
WHERE rp.rank = 1 
AND rp.total_supplycost > (SELECT AVG(total_supplycost) FROM ranked_part_suppliers)
ORDER BY r.r_name, np.n_name, rp.p_name;
