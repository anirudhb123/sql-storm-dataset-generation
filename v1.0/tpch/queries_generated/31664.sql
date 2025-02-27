WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 0 AS Level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) 

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.Level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.Level < 3
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 100000
),
PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS TotalAvailable
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    sh.s_name AS SupplierName,
    n.n_name AS NationName,
    c.c_name AS CustomerName,
    p.p_name AS PartName,
    COALESCE(psi.TotalAvailable, 0) AS TotalAvailableParts,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS Revenue,
    COUNT(DISTINCT o.o_orderkey) AS OrderCount
FROM SupplierHierarchy sh
LEFT JOIN nation n ON sh.s_nationkey = n.n_nationkey
LEFT JOIN lineitem l ON l.l_suppkey = sh.s_suppkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN TopCustomers c ON c.c_custkey = o.o_custkey
LEFT JOIN PartSupplierInfo psi ON l.l_partkey = psi.p_partkey 
WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY sh.s_name, n.n_name, c.c_name, p.p_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) IS NOT NULL 
ORDER BY Revenue DESC;
