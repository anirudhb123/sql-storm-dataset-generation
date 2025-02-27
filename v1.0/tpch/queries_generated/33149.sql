WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, 1 AS level
    FROM orders 
    WHERE o_orderdate >= DATE '2023-01-01'
    UNION ALL
    SELECT o.o_orderkey, o.o_custkey, oh.level + 1
    FROM orders o
    INNER JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE oh.level < 5
),
SupplierStats AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
CustomerPurchaseStats AS (
    SELECT c.c_custkey, COUNT(DISTINCT o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    p.p_name,
    s.s_name,
    COALESCE(order_stats.total_orders, 0) AS order_count,
    COALESCE(order_stats.total_spent, 0) AS total_spent,
    supplier_stats.total_available,
    supplier_stats.avg_supplycost,
    ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY supplier_stats.avg_supplycost DESC) as rank
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN CustomerPurchaseStats order_stats ON s.s_nationkey = order_stats.c_custkey
LEFT JOIN SupplierStats supplier_stats ON p.p_partkey = supplier_stats.ps_partkey
WHERE p.p_size >= 10 AND (s.s_acctbal IS NOT NULL OR s.s_comment LIKE '%premium%')
ORDER BY p.p_name, rank
LIMIT 100;
