WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
), 
OrdersWithTotal AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
), 
CustomerOrderStatistics AS (
    SELECT c.c_custkey, c.c_name, o.total_order_value, 
           COUNT(o.o_orderkey) AS order_count,
           MAX(o.total_order_value) AS max_order_value
    FROM customer c
    LEFT JOIN OrdersWithTotal o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey, c.c_name
), 
SuspiciousOrders AS (
    SELECT o.o_orderkey, o.o_custkey
    FROM orders o
    WHERE EXISTS (
        SELECT 1 
        FROM lineitem l 
        WHERE l.l_orderkey = o.o_orderkey 
        AND l.l_discount > 0.5
    )
)
SELECT cs.c_name, cs.order_count, cs.max_order_value, 
       COALESCE(ss.supp_name, 'Unknown Supplier') AS supplier_name, 
       COUNT(DISTINCT so.o_orderkey) AS suspicious_orders
FROM CustomerOrderStatistics cs
LEFT JOIN RankedSuppliers rs ON rs.rank = 1 AND rs.s_suppkey = ANY (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    JOIN part p ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > 100 AND p.p_size BETWEEN 20 AND 50
)
LEFT JOIN (
    SELECT DISTINCT s.s_suppkey, s.s_name AS supp_name
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
) ss ON ss.s_suppkey = ANY (
    SELECT ps.ps_suppkey 
    FROM partsupp ps
    WHERE ps.ps_availqty < 5
)
LEFT JOIN SuspiciousOrders so ON cs.c_custkey = so.o_custkey
WHERE cs.order_count > 0
AND (cs.max_order_value IS NOT NULL OR cs.order_count < 3)
GROUP BY cs.c_name, cs.order_count, cs.max_order_value, ss.supp_name
ORDER BY cs.max_order_value DESC
LIMIT 10 OFFSET 5;
