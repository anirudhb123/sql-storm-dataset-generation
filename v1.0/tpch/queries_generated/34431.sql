WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s2.s_acctbal) FROM supplier s2
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.nationkey = sh.nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost, 
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > (
        SELECT AVG(ps2.ps_availqty) FROM partsupp ps2
    )
)
SELECT 
    c.c_name AS customer_name,
    SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_sales,
    RANK() OVER (PARTITION BY c.c_custkey ORDER BY SUM(lo.l_extendedprice * (1 - lo.l_discount)) DESC) AS sales_rank,
    sh.level AS supplier_level
FROM CustomerOrders co
JOIN lineitem lo ON co.c_custkey = lo.l_orderkey
LEFT JOIN SupplierHierarchy sh ON lo.l_suppkey = sh.s_suppkey
JOIN PartSupplier ps ON lo.l_partkey = ps.p_partkey 
WHERE lo.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY c.c_custkey, c.c_name, sh.level
HAVING SUM(lo.l_extendedprice * (1 - lo.l_discount)) > (
    SELECT AVG(total_spent) FROM CustomerOrders
)
ORDER BY total_sales DESC;
