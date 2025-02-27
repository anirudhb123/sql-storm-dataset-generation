WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_acctbal, s.s_comment, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s2.s_acctbal) 
        FROM supplier s2 
        WHERE s2.s_nationkey = s.s_nationkey
    )
    UNION ALL
    SELECT sh.s_suppkey, sh.s_name, sh.s_address, sh.s_nationkey, sh.s_acctbal, sh.s_comment, sh.level + 1
    FROM SupplierHierarchy sh
    JOIN supplier s ON sh.s_nationkey = s.s_nationkey
    WHERE s.s_acctbal < sh.s_acctbal
),
HighValueCustomers AS (
    SELECT c.c_custkey, COUNT(DISTINCT o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > (
        SELECT AVG(c2.c_acctbal)
        FROM customer c2
    )
    GROUP BY c.c_custkey
),
PartStats AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available, 
           AVG(ps.ps_supplycost) AS avg_cost,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY AVG(ps.ps_supplycost) DESC) AS cost_rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT DISTINCT s.s_name, c.c_name, p.p_name, 
       coalesce(NULLIF(ph.total_available, 0), 'No Availability') AS availability_status,
       ps.avg_cost,
       CASE 
           WHEN hvc.order_count > 10 THEN 'High Volume'
           ELSE 'Medium or Low Volume'
       END AS customer_value_segment
FROM SupplierHierarchy s
FULL OUTER JOIN HighValueCustomers hvc ON s.s_nationkey = hvc.c_custkey
JOIN PartStats ps ON ps.cost_rank = 1
LEFT JOIN part p ON p.p_partkey = ps.p_partkey
WHERE (s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000)
   OR (hvc.total_value IS NOT NULL AND hvc.total_value > 5000)
ORDER BY s.s_name, hvc.total_value DESC, ps.avg_cost;
