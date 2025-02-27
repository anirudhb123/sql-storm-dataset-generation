WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s2.s_acctbal) 
        FROM supplier s2
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
part_ext_price AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
nation_summary AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
           SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    COALESCE(ps.total_supply_cost, 0) AS total_supply_cost,
    ns.supplier_count,
    ns.total_acctbal,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ns.total_acctbal DESC) AS acctbal_rank,
    CASE 
        WHEN ns.total_acctbal IS NULL THEN 'No suppliers'
        ELSE 'Has suppliers'
    END AS supplier_status
FROM 
    part p
LEFT JOIN 
    part_ext_price ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    nation_summary ns ON ns.n_nationkey IN (
        SELECT DISTINCT s.s_nationkey
        FROM supplier s
        WHERE s.s_suppkey IN (SELECT sh.s_suppkey FROM supplier_hierarchy sh)
    )
WHERE 
    p.p_size > 10 AND 
    (p.p_comment LIKE '%fragile%' OR p.p_comment IS NULL)
ORDER BY 
    p.p_partkey;
