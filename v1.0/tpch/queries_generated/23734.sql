WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
PartStats AS (
    SELECT p.p_partkey, COUNT(ps.ps_suppkey) AS total_suppliers, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
CustomerStats AS (
    SELECT c.c_custkey,
           COUNT(o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent,
           ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(o.o_totalprice) DESC) AS rank_within_segment
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    r.r_name,
    n.n_name,
    ps.total_suppliers,
    ps.avg_supplycost,
    cs.total_orders,
    cs.total_spent,
    sh.level AS supplier_level,
    COALESCE(cs.rank_within_segment, 0) AS segment_rank,
    CASE 
        WHEN cs.total_spent IS NOT NULL AND sh.level > 1 THEN 'Frequent & High Tier'
        WHEN cs.total_spent IS NULL THEN 'No Orders'
        ELSE 'Other'
    END AS customer_classification
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN PartStats ps ON ps.total_suppliers > 0
LEFT JOIN CustomerStats cs ON cs.total_orders > 0
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = n.n_nationkey
WHERE COALESCE(sh.level, 0) <= (SELECT MAX(level) FROM SupplierHierarchy)
ORDER BY r.r_name, n.n_name, ps.total_suppliers DESC, cs.total_spent DESC;
