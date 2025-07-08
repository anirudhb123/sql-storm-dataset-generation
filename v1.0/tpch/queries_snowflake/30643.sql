
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_acctbal > 50000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_nationkey,
           RANK() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
),
OrderStats AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_partkey) AS unique_parts,
           MAX(l.l_discount) AS max_discount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
)
SELECT r.r_name, 
       COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
       SUM(os.total_revenue) AS total_revenue,
       LISTAGG(DISTINCT tc.c_name, ', ') AS top_customers,
       AVG(tc.c_acctbal) AS avg_customer_balance
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN OrderStats os ON sh.s_suppkey = os.o_custkey
LEFT JOIN TopCustomers tc ON os.o_custkey = tc.c_custkey 
WHERE os.total_revenue > 1000 AND tc.rank <= 3
GROUP BY r.r_name
HAVING COUNT(DISTINCT sh.s_suppkey) > 5
ORDER BY total_revenue DESC, r.r_name;
