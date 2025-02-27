WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
TotalOrderAmounts AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_custkey
),
NationsWithSuppliers AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
RankedCustomers AS (
    SELECT c.c_custkey, c.c_name, r.total_amount,
           RANK() OVER (ORDER BY r.total_amount DESC) AS rank
    FROM customer c
    JOIN TotalOrderAmounts r ON c.c_custkey = r.o_custkey
    WHERE r.total_amount > 1000
)
SELECT 
    n.n_name AS nation_name,
    sh.s_name AS supplier_name,
    r.c_name AS customer_name,
    r.total_amount,
    CASE 
        WHEN r.rank <= 10 THEN 'Top Customer' 
        ELSE 'Regular Customer' 
    END AS customer_rank
FROM SupplierHierarchy sh
JOIN NationsWithSuppliers ns ON sh.s_nationkey = ns.n_nationkey
JOIN RankedCustomers r ON r.total_amount > 5000
LEFT JOIN lineitem l ON r.c_custkey = l.l_orderkey
WHERE l.l_returnflag = 'N'
AND l.l_shipdate IS NULL
ORDER BY ns.supplier_count DESC, r.total_amount DESC;
