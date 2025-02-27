WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, NULL::integer AS parent_suppkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.s_suppkey AS parent_suppkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_acctbal < sh.s_acctbal * 0.9
),

PartStats AS (
    SELECT p.p_partkey, 
           p.p_name, 
           SUM(ps.ps_availqty) AS total_availqty, 
           AVG(ps.ps_supplycost) AS avg_supplycost,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),

CustomerOrders AS (
    SELECT c.c_custkey, 
           c.c_name, 
           SUM(o.o_totalprice) AS total_spent, 
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),

RankedOrders AS (
    SELECT c.c_custkey, 
           c.c_name, 
           o.o_orderstatus, 
           o.o_orderdate, 
           RANK() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
)

SELECT p.p_name,
       ps.total_availqty,
       ps.avg_supplycost,
       cs.total_spent,
       cs.order_count,
       CASE 
           WHEN cs.total_spent IS NULL THEN 'No Orders'
           WHEN cs.order_count > 5 THEN 'Frequent Buyer'
           ELSE 'Occasional Buyer'
       END AS buyer_category,
       sh.level
FROM PartStats ps
LEFT JOIN CustomerOrders cs ON cs.order_count > 0
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey IN (SELECT ps.s_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey)
WHERE ps.total_availqty > 1000 
  AND (cs.total_spent IS NOT NULL OR ps.avg_supplycost < 50)
ORDER BY ps.total_availqty DESC, cs.total_spent DESC NULLS LAST;
