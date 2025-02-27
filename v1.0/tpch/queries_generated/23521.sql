WITH RECURSIVE SuppHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 as level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) -- Suppliers with above-average account balance
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SuppHierarchy sh ON s.s_nationkey = sh.s_nationkey AND sh.level < 10 -- Limit recursion to 10 levels
),
PartMetrics AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
           COUNT(DISTINCT s.s_suppkey) AS suppliers_count,
           MAX(l.l_extendedprice * (1 - l.l_discount)) AS max_possible_revenue
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_mfgr
),
BestParts AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY p_mfgr ORDER BY total_supplycost DESC) as rn
    FROM PartMetrics
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS total_orders,
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY o.o_orderdate) AS median_order_date
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT bh.p_partkey, bh.p_name, bh.total_supplycost, bh.suppliers_count, bh.max_possible_revenue,
       co.total_spent, co.total_orders, co.median_order_date
FROM BestParts bh
JOIN CustomerOrders co ON bh.suppliers_count > (SELECT AVG(suppliers_count) FROM BestParts) -- Compare suppliers count against average
WHERE bh.rn = 1 -- Top parts per manufacturer
  AND bh.max_possible_revenue IS NOT NULL
  AND bh.total_supplycost > 2500.00
  AND EXISTS (SELECT 1 FROM SuppHierarchy sh WHERE sh.s_nationkey = bh.p_partkey) -- Establishes a relation with supplier hierarchy
ORDER BY bh.total_supplycost DESC, co.total_spent ASC
LIMIT 10;
