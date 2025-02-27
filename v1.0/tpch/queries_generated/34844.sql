WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS order_level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT oh.o_orderkey, oh.o_orderdate, oh.o_totalprice, oh.order_level + 1
    FROM OrderHierarchy oh
    JOIN orders o ON oh.o_orderkey = o.o_custkey
),
SupplierStats AS (
    SELECT ps.ps_suppkey, SUM(ps.ps_supplycost) AS total_supply_cost, COUNT(ps.ps_partkey) AS total_parts
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS num_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT c.*, ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS rank
    FROM CustomerOrders c
    WHERE total_spent > 5000
),
PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, s.s_name
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    r.r_name,
    n.n_name AS nation_name,
    SUM(COALESCE(l.l_extendedprice * (1 - l.l_discount), 0)) AS total_revenue,
    AVG(l.l_discount) AS avg_discount,
    STRING_AGG(DISTINCT ps.s_name) AS supplier_names
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN HighValueCustomers hvc ON s.s_nationkey = hvc.c_nationkey
WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
AND (hvc.num_orders IS NULL OR hvc.num_orders >= 10)
GROUP BY r.r_name, n.n_name
HAVING total_revenue > 1000000
ORDER BY total_revenue DESC;
