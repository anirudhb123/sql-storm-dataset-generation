WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
CustomerOrderCounts AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
HighValueOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT cs.c_custkey) AS customer_count,
    SUM(hvo.total_value) AS total_high_value_order,
    AVG(coc.order_count) AS avg_orders_per_customer,
    STRING_AGG(DISTINCT s.s_name) AS supplier_names,
    p.p_name,
    p.total_available
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN CustomerOrderCounts coc ON s.s_nationkey = coc.c_custkey
LEFT JOIN HighValueOrders hvo ON coc.c_custkey = hvo.o_orderkey
JOIN PartDetails p ON s.s_suppkey = p.p_partkey
JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE sh.level IS NOT NULL
GROUP BY r.r_name, p.p_name, p.total_available
HAVING SUM(hvo.total_value) > 10000
ORDER BY region_name, total_high_value_order DESC;
