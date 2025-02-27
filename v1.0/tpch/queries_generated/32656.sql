WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           CAST(s.s_name AS varchar(255)) AS hierarchy_path,
           1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000.00
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           CONCAT(h.hierarchy_path, ' -> ', s.s_name),
           h.level + 1
    FROM supplier s
    JOIN SupplierHierarchy h ON s.s_nationkey = h.s_nationkey
    WHERE s.s_acctbal > h.s_acctbal
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           SUM(l.l_discount) OVER (PARTITION BY o.o_orderkey) AS total_discount
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
),
CustomerInfo AS (
    SELECT c.c_custkey, c.c_name, n.n_name AS nation
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE c.c_acctbal < 500.00
)
SELECT c.c_name, s.hierarchy_path, SUM(o.o_totalprice) AS total_spent,
       COUNT(DISTINCT o.o_orderkey) AS order_count,
       COALESCE(MAX(o.total_discount), 0) AS max_discount
FROM CustomerInfo c
LEFT JOIN SupplierHierarchy s ON s.s_nationkey = c.nation
LEFT JOIN OrderSummary o ON c.c_custkey = o.o_orderkey 
GROUP BY c.c_name, s.hierarchy_path
HAVING total_spent > 10000.00 OR s.s_acctbal IS NULL
ORDER BY total_spent DESC
LIMIT 10;
