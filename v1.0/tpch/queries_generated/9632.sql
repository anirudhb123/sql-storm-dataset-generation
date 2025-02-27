WITH ranked_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_mktsegment,
           RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rnk
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
),
top_segments AS (
    SELECT mktsegment, MAX(o_totalprice) AS max_totalprice
    FROM ranked_orders
    WHERE rnk <= 10
    GROUP BY mktsegment
),
supplier_info AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
)
SELECT n.n_name, r.r_name, COUNT(DISTINCT o.o_orderkey) AS order_count,
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       ROUND(AVG(s.total_supply_cost), 2) AS avg_supply_cost
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN supplier_info s ON l.l_suppkey = s.s_suppkey
WHERE o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
  AND EXISTS (SELECT 1 FROM top_segments ts WHERE ts.max_totalprice = o.o_totalprice)
GROUP BY n.n_name, r.r_name
ORDER BY total_revenue DESC, order_count DESC
LIMIT 50;
