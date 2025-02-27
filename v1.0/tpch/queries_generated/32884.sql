WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           CAST(s.s_name AS VARCHAR(100)) AS full_name,
           1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           CONCAT(sh.full_name, ' > ', s.s_name),
           sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 10000 AND sh.level < 5
),
OrderStats AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate
),
CustomerRank AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal,
           NTILE(5) OVER (ORDER BY c.c_acctbal DESC) AS acctbal_tile
    FROM customer c
)
SELECT n.n_name, 
       COUNT(DISTINCT sh.s_suppkey) AS num_suppliers,
       SUM(COALESCE(os.total_sales, 0)) AS total_sales,
       AVG(cr.c_acctbal) AS avg_customer_acctbal
FROM nation n
LEFT JOIN SupplierHierarchy sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN OrderStats os ON os.o_orderkey IN (SELECT o.o_orderkey 
                                               FROM orders o 
                                               JOIN customer c ON o.o_custkey = c.c_custkey
                                               WHERE c.c_nationkey = n.n_nationkey)
LEFT JOIN CustomerRank cr ON cr.c_nationkey = n.n_nationkey
GROUP BY n.n_name
HAVING SUM(COALESCE(os.total_sales, 0)) > 100000
ORDER BY num_suppliers DESC, avg_customer_acctbal DESC;
