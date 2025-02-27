WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 
           1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 
           sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),

TotalPricePerCustomer AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),

SupplierPartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, s.s_name, 
           ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
)

SELECT 
    c.c_name AS customer_name, 
    tp.total_spent, 
    sp.p_name AS part_name, 
    COALESCE(spd.s_name, 'No Supplier') AS supplier_name,
    spd.ps_availqty, 
    spd.ps_supplycost * (1 - COALESCE(l.l_discount, 0)) AS effective_cost,
    sh.level AS supplier_level
FROM TotalPricePerCustomer tp
LEFT JOIN lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = tp.c_custkey)
LEFT JOIN SupplierPartDetails spd ON spd.p_partkey = l.l_partkey AND spd.rn = 1
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = spd.s_suppkey 
WHERE tp.total_spent > 1000
ORDER BY tp.total_spent DESC, c.c_name;

