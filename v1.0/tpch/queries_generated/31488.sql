WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_suppkey = (SELECT MIN(s_suppkey) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
CustomerOrderTotals AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierStats AS (
    SELECT p.p_partkey, 
           p.p_name, 
           SUM(ps.ps_availqty) AS total_available, 
           AVG(ps.ps_supplycost) AS average_cost,
           ROW_NUMBER() OVER (ORDER BY AVG(ps.ps_supplycost) DESC) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
HighSpendingCustomers AS (
    SELECT c.c_custkey, c.c_name
    FROM CustomerOrderTotals cot
    WHERE cot.total_spent > (SELECT AVG(total_spent) FROM CustomerOrderTotals)
)
SELECT DISTINCT 
    c.c_name AS customer_name,
    sh.s_name AS supplier_name,
    p.p_name AS part_name,
    ps.total_available,
    ps.average_cost,
    CASE 
        WHEN ps.total_available IS NULL THEN 'Not Available' 
        ELSE 'Available' 
    END AS availability_status
FROM HighSpendingCustomers c
LEFT JOIN SupplierHierarchy sh ON c.c_custkey = sh.s_suppkey
CROSS JOIN PartSupplierStats ps
WHERE 
    (c.c_custkey % 2 = 0 OR sh.s_nationkey IS NULL)
    AND ps.rank <= 10
ORDER BY c.c_name, ps.average_cost DESC;
