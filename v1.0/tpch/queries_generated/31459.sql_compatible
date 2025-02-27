
WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, o.o_orderdate, 
           1 AS order_level
    FROM orders o
    WHERE o.o_orderdate >= '1995-01-01'
    UNION ALL
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice * 0.9, 
           o.o_orderdate, oh.order_level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE oh.order_level < 3
),
SupplierSummary AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_available
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
    GROUP BY s.s_suppkey, s.s_name
),
CustomerMetrics AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    p.p_name,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS revenue,
    COALESCE(cs.order_count, 0) AS total_orders,
    COALESCE(cs.avg_order_value, 0) AS avg_order_spent,
    COALESCE(ss.total_available, 0) AS supplier_avail_qty
FROM part p
LEFT JOIN lineitem li ON p.p_partkey = li.l_partkey
LEFT JOIN CustomerMetrics cs ON li.l_orderkey = cs.c_custkey
LEFT JOIN SupplierSummary ss ON li.l_suppkey = ss.s_suppkey
WHERE p.p_retailprice > 50.00
AND p.p_size IS NOT NULL
AND li.l_shipdate BETWEEN '1995-01-01' AND '1995-12-31'
GROUP BY p.p_name, cs.order_count, cs.avg_order_value, ss.total_available
HAVING SUM(li.l_extendedprice * (1 - li.l_discount)) > 10000
ORDER BY revenue DESC
LIMIT 10;
