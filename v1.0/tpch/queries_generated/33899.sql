WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 5
),
CustomerOrderTotal AS (
    SELECT o.o_custkey, SUM(o.o_totalprice) AS total_spent
    FROM orders o
    GROUP BY o.o_custkey
),
LineItemStats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS line_count,
        AVG(l.l_quantity) AS avg_quantity,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS return_count
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    n.n_name,
    r.r_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    COALESCE(SUM(c.total_spent), 0) AS total_customer_spent,
    MAX(ls.total_revenue) AS max_order_revenue,
    AVG(ls.avg_quantity) AS avg_order_quantity
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN CustomerOrderTotal c ON s.s_suppkey = c.o_custkey
JOIN LineItemStats ls ON ls.l_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    WHERE o.o_orderstatus = 'O'
) 
WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal BETWEEN 1000 AND 5000
GROUP BY n.n_name, r.r_name
HAVING COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY avg_order_quantity DESC
LIMIT 10;
