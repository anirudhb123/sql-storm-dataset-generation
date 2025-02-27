WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS depth
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.depth + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) * 0.8
),
TotalSales AS (
    SELECT c.c_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY c.c_custkey
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, ts.total_sales, 
           RANK() OVER (ORDER BY ts.total_sales DESC) AS sales_rank
    FROM customer c
    JOIN TotalSales ts ON c.c_custkey = ts.c_custkey
    WHERE ts.total_sales IS NOT NULL
)
SELECT TOP 10
    pc.p_partkey,
    pc.p_name,
    SUM(l.l_extendedprice) AS total_revenue,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
    COALESCE(SUM(c.c_acctbal), 0) AS total_customer_acctbal
FROM part pc
LEFT JOIN lineitem l ON pc.p_partkey = l.l_partkey
LEFT JOIN partsupp ps ON pc.p_partkey = ps.ps_partkey
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = ps.ps_suppkey
LEFT JOIN TopCustomers c ON c.c_custkey = l.l_suppkey
GROUP BY pc.p_partkey, pc.p_name
HAVING COUNT(DISTINCT l.l_orderkey) > 5
ORDER BY total_revenue DESC, pc.p_name;
