WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_suppkey <> sh.s_suppkey AND sh.level < 5
),
OrderAmounts AS (
    SELECT o_orderkey, SUM(l_extendedprice * (1 - l_discount)) AS total_amount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l_returnflag = 'N'
    GROUP BY o_orderkey
),
CustomerSummary AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, COALESCE(SUM(o.o_totalprice), 0) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
)
SELECT 
    sh.s_name AS supplier_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    AVG(cs.total_spent) AS avg_customer_spent,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(oa.total_amount) AS total_order_amount
FROM SupplierHierarchy sh
JOIN nation n ON sh.s_nationkey = n.n_nationkey
JOIN customer c ON sh.s_nationkey = c.c_nationkey
LEFT JOIN CustomerSummary cs ON c.c_custkey = cs.c_custkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN OrderAmounts oa ON o.o_orderkey = oa.o_orderkey
GROUP BY sh.s_name, n.n_name
HAVING COUNT(DISTINCT o.o_orderkey) > 0
    AND SUM(oa.total_amount) / NULLIF(COUNT(DISTINCT o.o_orderkey), 0) > 1000
ORDER BY total_order_amount DESC;
