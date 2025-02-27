WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_orderstatus,
           1 AS level
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_orderstatus,
           oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
)
, CustomerPurchases AS (
    SELECT c.c_custkey, c.c_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    c.c_name, 
    cp.total_spent, 
    psi.p_name, 
    psi.total_available,
    ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY cp.total_spent DESC) AS purchase_rank,
    CASE WHEN cp.total_spent IS NULL THEN 'NO PURCHASES' ELSE 'PURCHASED' END AS purchase_status
FROM CustomerPurchases cp
FULL OUTER JOIN PartSupplierInfo psi ON psi.total_available > 0
LEFT JOIN customer c ON cp.c_custkey = c.c_custkey
WHERE c.c_nationkey IN (SELECT DISTINCT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'A%')
ORDER BY total_spent DESC NULLS LAST, purchase_status;
