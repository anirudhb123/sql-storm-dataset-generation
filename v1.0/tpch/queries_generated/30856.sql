WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (1000.00 + sh.level * 500)
),
OrderMetrics AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(l.l_orderkey) AS lineitem_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    p.p_name,
    COALESCE(SUM(CASE WHEN sh.level > 0 THEN ps.ps_availqty END), 0) AS total_available_qty,
    COALESCE(MAX(cs.total_spent), 0) AS highest_customer_spent,
    AVG(om.net_revenue) AS average_order_revenue
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
LEFT JOIN OrderMetrics om ON om.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_orderkey = om.o_orderkey LIMIT 1)
LEFT JOIN CustomerSummary cs ON cs.c_custkey = (SELECT c.c_custkey FROM customer c WHERE cs.total_orders > 0 LIMIT 1)
WHERE 
    p.p_retailprice > 50.00 
    AND p.p_size IS NOT NULL
GROUP BY p.p_name
ORDER BY total_available_qty DESC, highest_customer_spent DESC
LIMIT 10;
