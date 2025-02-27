WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh 
    ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
PartStats AS (
    SELECT p.p_partkey,
           p.p_name,
           SUM(ps.ps_availqty) AS total_available,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT c.c_custkey, 
           c.c_name, 
           COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT c.*, 
           SUM(CASE 
               WHEN o.o_orderstatus = 'F' THEN o.o_totalprice 
               ELSE 0 
           END) AS finished_order_value
    FROM CustomerOrders c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 5
),
FinalResults AS (
    SELECT p.p_name,
           p.total_available,
           cu.c_name,
           cu.finished_order_value,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY cu.finished_order_value DESC) AS rn
    FROM PartStats p
    JOIN TopCustomers cu ON p.total_available > (SELECT AVG(total_available) FROM PartStats)
)
SELECT DISTINCT 
       f.p_name, 
       f.total_available, 
       f.c_name, 
       f.finished_order_value,
       (CASE WHEN f.finished_order_value IS NULL THEN 'No Orders' ELSE 'Has Orders' END) AS order_status
FROM FinalResults f
LEFT JOIN supplier s ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'INDIA')
WHERE f.rn = 1
  AND (f.finished_order_value IS NOT NULL OR f.finished_order_value < 1000)
ORDER BY f.total_available DESC
LIMIT 100;
