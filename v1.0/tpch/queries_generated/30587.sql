WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > 5000.00
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 5000.00 AND sh.level < 5
),
CustomerOrderTotals AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
PartSupplierDetails AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost, 
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
HighValueSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
)
SELECT DISTINCT c.c_name, ct.total_spent, p.p_name, ps.total_value
FROM customer c
LEFT JOIN CustomerOrderTotals ct ON c.c_custkey = ct.c_custkey
LEFT JOIN PartSupplierDetails p ON p.rn = 1
JOIN HighValueSuppliers ps ON ps.s_suppkey = 
    (SELECT ps2.ps_suppkey 
     FROM partsupp ps2 
     WHERE ps2.ps_partkey = p.p_partkey 
     ORDER BY ps2.ps_supplycost DESC 
     LIMIT 1)
WHERE ct.total_spent IS NOT NULL
AND (ct.total_spent > 10000 OR c.c_name LIKE '%Inc%')
ORDER BY ct.total_spent DESC, ps.total_value ASC;
