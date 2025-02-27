WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey,
           0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey,
           sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
TotalSales AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY o.o_orderkey
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
    ORDER BY total_spent DESC
    LIMIT 5
)
SELECT p.p_name, p.p_brand, p.p_retailprice,
       COALESCE(SUM(l.l_extendedprice), 0) AS total_sales,
       COALESCE(SUM(ps.ps_availqty), 0) AS total_available_qty,
       s.s_name AS supplier_name,
       CASE
           WHEN p.p_brand LIKE 'Brand%M%' THEN 'Premium'
           ELSE 'Regular'
       END AS brand_category,
       ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(l.l_extendedprice) DESC) AS sales_rank,
       CASE 
           WHEN s.s_acctbal IS NULL THEN 'Not Applicable' 
           ELSE s.s_name 
       END AS supplier_info
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN TopCustomers tc ON s.s_nationkey = tc.c_custkey
WHERE p.p_size BETWEEN 1 AND 50
  AND p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
  AND (p.p_comment IS NOT NULL OR p.p_container IS NOT NULL)
GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, s.s_name
HAVING total_sales > 1000
ORDER BY total_sales DESC, p.p_name;
