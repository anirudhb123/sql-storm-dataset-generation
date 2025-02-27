WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_nationkey = (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
RankedLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey, l.l_quantity, l.l_extendedprice,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS rank_order
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '2023-01-01' AND l.l_shipdate < DATE '2023-10-01'
),
AverageCost AS (
    SELECT ps.ps_partkey, AVG(ps.ps_supplycost) as avg_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT p.p_name, SUM(li.l_quantity) AS total_quantity, 
       SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
       AVG(ac.avg_cost) AS average_supply_cost,
       COUNT(DISTINCT s.s_suppkey) AS supplier_count,
       r.r_name AS region
FROM part p
JOIN RankedLineItems li ON p.p_partkey = li.l_partkey
LEFT JOIN SupplierHierarchy s ON li.l_suppkey = s.s_suppkey
JOIN region r ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey)
JOIN AverageCost ac ON p.p_partkey = ac.ps_partkey
WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size < 10)
GROUP BY p.p_name, r.r_name
HAVING total_revenue > 10000 AND COUNT(DISTINCT li.l_orderkey) > 5
ORDER BY total_revenue DESC, total_quantity ASC
LIMIT 50;
