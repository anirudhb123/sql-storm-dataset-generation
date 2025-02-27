WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level, s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal > 1000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1, (sh.s_acctbal + s.s_acctbal) AS s_acctbal
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),

PartSupplierStats AS (
    SELECT p.p_partkey, p.p_name, COUNT(ps.ps_suppkey) AS num_suppliers, SUM(ps.ps_supplycost) AS total_supplycost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),

CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),

TopCustomers AS (
    SELECT c.c_custkey, c.c_name, c.total_spent, ROW_NUMBER() OVER (ORDER BY c.total_spent DESC) AS rn
    FROM CustomerOrders c
),

SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, n.n_name, s.s_acctbal
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL
)

SELECT 
    p.p_partkey,
    p.p_name,
    ps.num_suppliers,
    ps.total_supplycost,
    sh.level AS supplier_hierarchy_level,
    tc.total_spent AS top_customer_spent,
    si.s_name AS supplier_name,
    si.n_name AS supplier_nation
FROM PartSupplierStats ps
JOIN SupplierHierarchy sh ON ps.num_suppliers > 10
JOIN TopCustomers tc ON tc.rn <= 5
LEFT JOIN SupplierInfo si ON si.s_acctbal = ps.total_supplycost
WHERE ps.total_supplycost > 50000
ORDER BY ps.total_supplycost DESC, sh.level;
