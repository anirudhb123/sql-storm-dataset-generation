WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 10
),
PartStats AS (
    SELECT p.p_partkey, 
           p.p_name, 
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
           AVG(ps.ps_supplycost) AS avg_supply_cost,
           SUM(l.l_extendedprice) AS total_extended_price
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
    GROUP BY p.p_partkey, p.p_name
),
NationRanked AS (
    SELECT n.n_nationkey, 
           n.n_name, 
           RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(c.c_acctbal) DESC) AS nation_rank
    FROM nation n
    INNER JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_nationkey, n.n_name, n.n_regionkey
)
SELECT 
    n.n_name, 
    ps.supplier_count, 
    ps.avg_supply_cost,
    ps.total_extended_price,
    sh.s_name AS supplier_name,
    CASE 
        WHEN ns.nation_rank IS NULL THEN 'N/A' 
        ELSE CAST(ns.nation_rank AS VARCHAR) 
    END AS nation_ranking
FROM PartStats ps
JOIN SupplierHierarchy sh ON ps.supplier_count > 2
LEFT OUTER JOIN NationRanked ns ON ns.n_nationkey = sh.s_nationkey
WHERE ps.total_extended_price > (
    SELECT AVG(total_extended_price) * 0.5 FROM PartStats
)
ORDER BY ps.supplier_count DESC, ps.avg_supply_cost ASC
LIMIT 50
OFFSET (SELECT COUNT(*) FROM customer WHERE c_acctbal > 5000) % 100;
