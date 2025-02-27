WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           RANK() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
), HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           CASE 
               WHEN c.c_acctbal IS NULL THEN 'Unknown'
               WHEN c.c_acctbal < 500 THEN 'Low Value'
               WHEN c.c_acctbal BETWEEN 500 AND 2000 THEN 'Medium Value'
               ELSE 'High Value' 
           END AS cust_value
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
), OrdersWithDiscount AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_discount) AS total_discount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_discount > 0.05
    GROUP BY o.o_orderkey, o.o_custkey
), SupplierSales AS (
    SELECT ps.ps_suppkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey AND ps.ps_suppkey = l.l_suppkey
    GROUP BY ps.ps_suppkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT h.c_name, h.c_acctbal, r.s_name, r.s_acctbal AS supplier_acctbal, 
       COALESCE(s.total_sales, 0) AS supplier_total_sales,
       CASE 
           WHEN r.rnk = 1 THEN 'Top Supplier'
           ELSE 'Other Supplier' 
       END AS supplier_status,
       o.total_discount
FROM HighValueCustomers h
LEFT JOIN RankedSuppliers r ON h.c_custkey % 10 = r.s_suppkey % 10
LEFT JOIN SupplierSales s ON r.s_suppkey = s.ps_suppkey
JOIN OrdersWithDiscount o ON h.c_custkey = o.o_custkey
WHERE h.c_acctbal > 0 OR h.c_acctbal IS NULL
ORDER BY h.c_acctbal DESC, supplier_acctbal ASC;
