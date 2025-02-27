WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
    WHERE sh.level < 5
),
CustomerRanked AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 
           RANK() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS rank_per_nation
    FROM customer c
)
SELECT r.r_name, 
       COUNT(DISTINCT n.n_nationkey) AS nation_count,
       SUM(item_count) AS total_items,
       AVG(avg_price) AS average_price,
       STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers,
       MAX(COALESCE(c.c_acctbal, 0)) AS max_customer_balance
FROM region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN (
    SELECT ps.ps_partkey, 
           SUM(ps.ps_availqty) AS item_count, 
           AVG(p.p_retailprice) AS avg_price
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_partkey
) AS item_stats ON item_stats.ps_partkey IN (SELECT l.l_partkey FROM lineitem l)
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN CustomerRanked c ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = item_stats.ps_partkey ORDER BY l.l_extendedprice DESC LIMIT 1))
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name
HAVING SUM(CASE WHEN total_items = 0 THEN 1 ELSE 0 END) < 5
ORDER BY nation_count DESC, average_price DESC;
