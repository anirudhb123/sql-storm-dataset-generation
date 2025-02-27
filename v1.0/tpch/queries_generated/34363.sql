WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
TotalOrders AS (
    SELECT o_custkey, SUM(o_totalprice) AS total_spent
    FROM orders
    GROUP BY o_custkey
),
HighSpendingCustomers AS (
    SELECT c.c_custkey, c.c_name, tc.total_spent
    FROM customer c
    JOIN TotalOrders tc ON c.c_custkey = tc.o_custkey
    WHERE tc.total_spent > 50000
),
PartSupplierCounts AS (
    SELECT ps.partkey, COUNT(DISTINCT ps.suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.partkey
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, COUNT(DISTINCT ps.ps_partkey) AS part_count,
           RANK() OVER (ORDER BY COUNT(DISTINCT ps.ps_partkey) DESC) AS rank
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT c.c_name AS customer_name,
       COALESCE(s.s_name, 'Not Available') AS supplier_name,
       ph.partkey,
       pc.supplier_count,
       rs.part_count,
       rs.rank AS supplier_rank
FROM HighSpendingCustomers c
LEFT JOIN SupplierHierarchy sh ON c.c_nationkey = sh.s_nationkey
LEFT JOIN PartSupplierCounts pc ON pc.partkey IN (
    SELECT ps.ps_partkey
    FROM partsupp ps
    WHERE ps.ps_supplycost = (SELECT MAX(ps_supplycost) FROM partsupp)
)
LEFT JOIN RankedSuppliers rs ON rs.supplier_count = pc.supplier_count
LEFT JOIN part ph ON ph.p_partkey = pc.partkey
ORDER BY c.c_name, supplier_rank DESC;
