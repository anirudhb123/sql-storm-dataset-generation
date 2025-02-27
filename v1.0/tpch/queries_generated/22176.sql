WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey AND sh.level < 5
),
PartDetail AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, ps.ps_availqty,
           (CASE 
                WHEN ps.ps_supplycost > 100 THEN 'Expensive'
                WHEN ps.ps_supplycost BETWEEN 50 AND 100 THEN 'Moderate'
                ELSE 'Cheap'
            END) AS price_category
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
    HAVING total_lineitem > 50000
),
FinalReport AS (
    SELECT ch.cust.c_custkey, ch.cust.c_name, ch.orders.total_spent, ph.p_name AS part_name,
           ph.price_category, ph.ps_availqty,
           COUNT(od.o_orderkey) AS order_count
    FROM CustomerOrders ch
    LEFT JOIN OrderDetails od ON ch.c_custkey = od.o_orderkey
    LEFT JOIN PartDetail ph ON od.total_lineitem > ph.p_retailprice
    GROUP BY ch.c_custkey, ch.c_name, od.total_spent, ph.p_name, ph.price_category, ph.ps_availqty
)
SELECT *, 
       CASE 
           WHEN total_spent IS NULL THEN 'Unknown'
           ELSE total_spent::VARCHAR || ' spent'
       END AS spending_status
FROM FinalReport fr
WHERE fr.part_name IS NOT NULL
ORDER BY fr.total_spent DESC NULLS LAST;
