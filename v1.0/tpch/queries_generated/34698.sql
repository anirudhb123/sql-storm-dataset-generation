WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
    WHERE sh.level < 5
),
OrderedCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    C.c_name AS customer_name, 
    COALESCE(OC.total_spent, 0) AS total_spent, 
    COALESCE(SH.s_name, 'No Supplier') AS supplier_name,
    PD.p_name AS part_name,
    PD.total_cost,
    ROW_NUMBER() OVER (PARTITION BY C.c_custkey ORDER BY COALESCE(OC.total_spent, 0) DESC) AS rank
FROM customer C
LEFT JOIN OrderedCustomers OC ON C.c_custkey = OC.c_custkey
LEFT JOIN SupplierHierarchy SH ON C.c_nationkey = SH.s_nationkey
JOIN PartDetails PD ON SH.s_suppkey = PD.p_partkey
WHERE (OC.total_spent IS NOT NULL OR SH.s_name IS NOT NULL)
AND (PD.total_cost > 1000 OR PD.p_name LIKE 'Widget%')
ORDER BY total_spent DESC, supplier_name ASC;
