WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 5
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_totalprice > 1000
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    SUM(COALESCE(ps.ps_availqty, 0)) AS total_available_quantity,
    AVG(cus.total_spent) AS avg_customer_spending,
    COUNT(DISTINCT ho.o_orderkey) AS high_value_order_count,
    MAX(CASE WHEN ho.order_rank = 1 THEN ho.o_totalprice END) AS highest_order_value
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN CustomerOrderSummary cus ON s.s_suppkey = cus.c_custkey
LEFT JOIN HighValueOrders ho ON ho.o_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
)
WHERE s.s_acctbal > 5000 
GROUP BY r.r_name, n.n_name
HAVING SUM(ps.ps_availqty) > 0
ORDER BY region_name, nation_name;
