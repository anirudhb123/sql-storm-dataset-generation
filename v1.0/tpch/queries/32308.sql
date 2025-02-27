WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level 
    FROM supplier 
    WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey 
    WHERE sh.level < 5
),
AvgPartCost AS (
    SELECT ps_partkey, AVG(ps_supplycost) AS avg_cost 
    FROM partsupp 
    GROUP BY ps_partkey
),
PartRanking AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank,
           COALESCE(NULLIF(p.p_comment, ''), 'No Comment') AS sanitized_comment
    FROM part p
)
SELECT 
    rh.r_name, 
    SUM(COALESCE(oi.total_price, 0)) AS total_order_value,
    COUNT(DISTINCT l.l_orderkey) AS unique_orders,
    AVG(ap.avg_cost) AS average_part_supply_cost,
    STRING_AGG(DISTINCT pr.sanitized_comment, '; ') AS part_comments
FROM region rh
LEFT JOIN nation n ON n.n_regionkey = rh.r_regionkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN lineitem l ON l.l_suppkey = s.s_suppkey
LEFT JOIN orders o ON o.o_orderkey = l.l_orderkey
LEFT JOIN (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM lineitem l
    JOIN orders o ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1997-12-31'
    GROUP BY o.o_orderkey
) oi ON oi.o_orderkey = o.o_orderkey
JOIN AvgPartCost ap ON ap.ps_partkey = l.l_partkey
JOIN PartRanking pr ON pr.p_partkey = l.l_partkey
WHERE rh.r_name NOT LIKE '%%No%' AND s.s_acctbal > 0
GROUP BY rh.r_name
ORDER BY total_order_value DESC, unique_orders DESC;