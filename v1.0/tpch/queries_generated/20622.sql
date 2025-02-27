WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 1 AS level
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)

    UNION ALL

    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = (
        SELECT n.n_nationkey
        FROM nation n
        WHERE n.n_nationkey = ch.c_nationkey
        AND LENGTH(n.n_name) % 2 = 0
    )
    WHERE ch.level < 3
), PartStats AS (
    SELECT p.p_partkey, 
           p.p_name,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
           SUM(ps.ps_availqty) AS total_availability,
           SUM(ps.ps_supplycost) AS total_cost,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
), OrderStatusCounts AS (
    SELECT o.o_orderstatus, COUNT(*) AS order_count 
    FROM orders o
    GROUP BY o.o_orderstatus
), SupplierAnalysis AS (
    SELECT s.s_nationkey, 
           AVG(s.s_acctbal) AS avg_acctbal,
           MAX(s.s_acctbal) AS max_acctbal
    FROM supplier s
    GROUP BY s.s_nationkey
)
SELECT p.p_name, 
       p.total_availability,
       CASE 
           WHEN p.supplier_count > 0 THEN p.total_cost / p.supplier_count 
           ELSE NULL 
       END AS avg_supply_cost,
       ch.c_name as high_value_customers,
       o.order_count,
       CASE 
           WHEN o.order_count > (SELECT AVG(order_count) FROM OrderStatusCounts) THEN 'Above Average'
           ELSE 'Below Average'
       END AS order_status_analysis
FROM PartStats p
LEFT JOIN CustomerHierarchy ch ON p.supplier_count = ch.level
LEFT JOIN OrderStatusCounts o ON o.o_orderstatus = 'O'
WHERE p.rn = 1
ORDER BY p.p_name 
LIMIT 100
OFFSET 0;
