WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000.00
    UNION ALL
    SELECT sh.s_suppkey, s.s_name, sh.s_acctbal, s.s_nationkey, sh.level + 1
    FROM SupplierHierarchy sh
    JOIN supplier s ON sh.s_nationkey = s.s_nationkey AND sh.s_suppkey <> s.s_suppkey
    WHERE sh.level < 5
),
PartWithComments AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           CASE 
               WHEN p.p_comment IS NULL THEN 'Empty Comment' 
               ELSE p.p_comment 
           END AS adjusted_comment,
           RANK() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_size BETWEEN 1 AND 10
),
OrderStats AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(l.l_orderkey) AS line_count,
           o.o_orderdate
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
CustomerStats AS (
    SELECT c.c_custkey, 
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spend,
           MAX(o.o_orderpriority) AS highest_priority
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT ch.s_name, 
       p.p_name AS best_selling_part,
       cs.total_spend, 
       os.line_count,
       ch.level AS supplier_level,
       CASE 
           WHEN cs.order_count > 5 THEN 'Frequent Buyer'
           ELSE 'Occasional Buyer' 
       END AS customer_category
FROM SupplierHierarchy ch
JOIN PartWithComments p ON p.price_rank = 1
JOIN CustomerStats cs ON cs.total_spend > 5000
FULL OUTER JOIN OrderStats os ON os.line_count BETWEEN 1 AND 10 AND os.total_revenue IS NOT NULL
WHERE ch.s_acctbal IS NOT NULL
  AND (cs.highest_priority LIKE '1-URGENT%' OR ch.s_name NOT LIKE '%Corp%')
ORDER BY cs.total_spend DESC, os.total_revenue ASC
LIMIT 50;
