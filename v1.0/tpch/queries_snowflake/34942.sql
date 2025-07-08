
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
OrderSummary AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           COUNT(DISTINCT l.l_partkey) AS part_count,
           RANK() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rnk
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
CustomerOrder AS (
    SELECT c.c_custkey, c.c_name, os.total_price, os.part_count
    FROM customer c
    JOIN OrderSummary os ON c.c_custkey = os.o_orderkey
    WHERE os.rnk <= 5
)
SELECT DISTINCT p.p_partkey, p.p_name, p.p_retailprice, sh.s_name AS supplier_name,
       co.c_name AS customer_name, co.total_price, co.part_count
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier sh ON ps.ps_suppkey = sh.s_suppkey
LEFT JOIN CustomerOrder co ON p.p_partkey = co.part_count
WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
  AND (sh.s_name IS NOT NULL OR co.c_name IS NOT NULL)
ORDER BY p.p_partkey, co.c_name DESC
LIMIT 100;
