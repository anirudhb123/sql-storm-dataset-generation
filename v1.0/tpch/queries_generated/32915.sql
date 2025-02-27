WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierStats AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_avail,
           MAX(ps.ps_supplycost) AS max_supply_cost,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT DISTINCT 
    c.c_name AS customer_name,
    ps.p_name AS part_name,
    COALESCE(s.total_spent, 0) AS total_spent,
    COALESCE(ps.total_avail, 0) AS total_available,
    sh.level AS supplier_level
FROM CustomerOrderSummary s
FULL OUTER JOIN PartSupplierStats ps ON s.order_count > 5
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = (SELECT ps_suppkey 
                                                  FROM partsupp 
                                                  WHERE ps_partkey = ps.p_partkey 
                                                  ORDER BY ps_supplycost DESC LIMIT 1)
WHERE (s.order_count IS NULL OR s.total_spent > 5000) 
  AND (ps.total_avail IS NOT NULL AND ps.max_supply_cost > 100)
ORDER BY total_spent DESC NULLS LAST, supplier_level ASC;
