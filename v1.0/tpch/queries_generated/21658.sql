WITH RECURSIVE order_totals AS (
    SELECT o.o_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
supplier_info AS (
    SELECT s.s_suppkey,
           s.s_name,
           CASE WHEN SUM(ps.ps_availqty) IS NULL THEN 0 ELSE SUM(ps.ps_availqty) END AS total_available,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank_per_nation
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
customer_order_counts AS (
    SELECT c.c_custkey,
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           MAX(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice ELSE NULL END) AS latest_fulfilled_order_price
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT c.c_name,
       CASE 
           WHEN SUM(o.total_price) IS NULL THEN 'No Orders' 
           ELSE 'Total Orders: ' || COUNT(DISTINCT o.o_orderkey) 
       END AS order_summary,
       SUM(o.total_price) AS total_revenue,
       s.s_name AS supplier_name,
       s.total_available,
       COALESCE(c.order_count, 0) AS customer_order_count,
       c.latest_fulfilled_order_price,
       RANK() OVER (ORDER BY SUM(o.total_price) DESC) AS revenue_rank
FROM order_totals o
JOIN customer_order_counts c ON c.order_count > 0
LEFT JOIN supplier_info s ON s.rank_per_nation <= 5
GROUP BY c.c_name, s.s_name, s.total_available
HAVING SUM(o.total_price) IS NOT NULL
   OR COUNT(s.s_suppkey) > 0
ORDER BY total_revenue DESC NULLS LAST;
