WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_nationkey = s.s_nationkey
    WHERE sh.level < 5
),
PartSummary AS (
    SELECT ps.ps_partkey, SUM(l.l_quantity) AS total_quantity, AVG(l.l_extendedprice) AS avg_price
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_shipdate >= '2023-01-01'
    GROUP BY ps.ps_partkey
),
RegionStats AS (
    SELECT r.r_regionkey, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey
)
SELECT
    p.p_partkey,
    p.p_name,
    COALESCE(ps.total_quantity, 0) AS total_quantity,
    COALESCE(ps.avg_price, 0) AS avg_price,
    r.nation_count AS total_nations,
    s.s_name AS supplier_name,
    s.s_nationkey AS supplier_nation,
    CASE 
        WHEN s.s_acctbal IS NULL THEN 'Account balance missing'
        ELSE CONCAT('Account balance is ', CAST(s.s_acctbal AS VARCHAR))
    END AS account_balance,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY l.l_discount DESC) AS discount_rank
FROM part p
LEFT JOIN PartSummary ps ON p.p_partkey = ps.ps_partkey
JOIN RegionStats r ON r.nation_count > 5
LEFT JOIN supplier s ON s.s_suppkey = ps.ps_partkey
WHERE (s.s_nationkey IS NOT NULL AND s.s_acctbal > 0) 
   OR (s.s_nationkey IS NULL)
ORDER BY p.p_partkey, total_quantity DESC;
