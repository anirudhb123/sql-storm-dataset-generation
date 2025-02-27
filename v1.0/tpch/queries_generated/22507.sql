WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 0
),
HighValueParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           CASE 
               WHEN p.p_retailprice >= 100 THEN 'High Price'
               WHEN p.p_retailprice < 50 THEN 'Low Price'
               ELSE 'Medium Price'
           END AS price_category
    FROM part p
    WHERE p.p_size >= 10 OR p.p_name LIKE '%special%'
),
CustomerOrderCounts AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
QualifiedSuppliers AS (
    SELECT DISTINCT s.s_suppkey, s.s_name,
           CASE 
               WHEN SUM(ps.ps_supplycost) > 5000 THEN 'Premium'
               WHEN SUM(ps.ps_supplycost) BETWEEN 1000 AND 5000 THEN 'Standard'
               ELSE 'Budget'
           END AS supplier_tier
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
FinalReport AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           COALESCE(s.s_name, 'No Supplier') AS supplier_name,
           c.c_name AS customer_name,
           COALESCE(o.order_count, 0) AS order_count,
           CASE
               WHEN l.l_discount > 0 THEN 'Discount Applied'
               ELSE 'No Discount'
           END AS discount_status
    FROM HighValueParts p
    LEFT JOIN RankedSuppliers s ON s.rnk = 1
    LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
    LEFT JOIN CustomerOrderCounts o ON o.c_custkey = l.l_suppkey
    LEFT JOIN customer c ON c.c_custkey = o.c_custkey
)
SELECT *,
       CONCAT('Part:', p_partkey, ' Supplier:', COALESCE(supplier_name, 'N/A'), ' Customer:', COALESCE(customer_name, 'Unknown')) AS detail_summary
FROM FinalReport
WHERE price_category = 'High Price' OR discount_status = 'Discount Applied'
ORDER BY p_partkey, supplier_name NULLS LAST;
