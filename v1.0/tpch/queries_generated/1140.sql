WITH SupplierRanked AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
TotalSales AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '2023-01-01'
    GROUP BY o.o_custkey
),
TopCustomers AS (
    SELECT t.c_custkey, t.c_name, COALESCE(s.total_sales, 0) AS total_sales
    FROM customer t
    LEFT JOIN TotalSales s ON t.c_custkey = s.o_custkey
    WHERE t.c_acctbal > 1000
)
SELECT p.p_name, 
       COALESCE(sr.s_name, 'No Supplier') AS supplier_name, 
       tc.c_name AS customer_name, 
       tc.total_sales,
       p.p_retailprice * 1.1 AS adjusted_price
FROM part p
LEFT JOIN SupplierRanked sr ON sr.rank = 1 AND p.p_partkey = sr.s_partkey
JOIN TopCustomers tc ON tc.total_sales > 5000
WHERE p.p_size IS NOT NULL
  AND (p.p_type LIKE '%brass%' OR p.p_comment IS NULL)
ORDER BY adjusted_price DESC, tc.total_sales ASC;
