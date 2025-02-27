WITH SupplierCost AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderInfo AS (
    SELECT o.o_orderkey, o.o_orderstatus, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, COUNT(l.l_orderkey) AS item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY o.o_orderkey, o.o_orderstatus
),
CustomerTotals AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT r.r_name, COUNT(DISTINCT ct.c_custkey) AS total_customers,
       SUM(CASE WHEN oi.o_orderstatus = 'F' THEN oi.total_revenue ELSE 0 END) AS total_filled_revenue,
       SUM(sc.total_supplycost) AS total_supplier_cost,
       AVG(ct.total_spent) AS average_spent_per_customer
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN customer ct ON n.n_nationkey = ct.c_nationkey
LEFT JOIN OrderInfo oi ON ct.total_orders > 0
LEFT JOIN SupplierCost sc ON sc.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps JOIN lineitem l ON ps.ps_partkey = l.l_partkey)
GROUP BY r.r_name
ORDER BY total_customers DESC, total_filled_revenue DESC;
