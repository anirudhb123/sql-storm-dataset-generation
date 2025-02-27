WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 100000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
),
MonthlySales AS (
    SELECT 
        DATE_TRUNC('month', o.o_orderdate) AS sales_month,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY sales_month
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 5000
    ORDER BY total_spent DESC
    LIMIT 10
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(sh.level, 0) AS supplier_level,
    ts.c_name AS top_customer_name,
    ms.sales_month,
    ms.total_sales
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN TopCustomers ts ON ts.c_custkey = s.s_suppkey
LEFT JOIN MonthlySales ms ON ms.sales_month = DATE_TRUNC('month', cast('1998-10-01' as date))
WHERE p.p_retailprice > (
    SELECT AVG(p1.p_retailprice)
    FROM part p1
    WHERE p1.p_size > 10
) AND p.p_container IS NOT NULL
ORDER BY p.p_partkey, total_sales DESC;