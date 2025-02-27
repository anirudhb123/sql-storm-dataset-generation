WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey 
    WHERE s.s_acctbal > sh.s_acctbal
),
EligibleOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_shipdate >= '2023-01-01'
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(e.total_sales) AS total_spent
    FROM customer c
    JOIN EligibleOrders e ON c.c_custkey = e.o_custkey
    GROUP BY c.c_custkey, c.c_name
    ORDER BY total_spent DESC
    LIMIT 10
),
SupplierProducts AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty IS NOT NULL
),
SupplierPerformance AS (
    SELECT sh.s_suppkey, sh.s_name, SUM(sp.ps_availqty * sp.ps_supplycost) AS supplier_performance
    FROM SupplierHierarchy sh
    JOIN SupplierProducts sp ON sh.s_suppkey = sp.ps_suppkey
    GROUP BY sh.s_suppkey, sh.s_name
),
FinalBenchmark AS (
    SELECT tc.c_name, sp.s_name, sp.supplier_performance
    FROM TopCustomers tc
    JOIN SupplierPerformance sp ON tc.total_spent > sp.supplier_performance
)
SELECT f.c_name, f.s_name, f.supplier_performance
FROM FinalBenchmark f
ORDER BY f.supplier_performance DESC;
