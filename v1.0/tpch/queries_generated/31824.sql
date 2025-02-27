WITH RECURSIVE region_hierarchy AS (
    SELECT r_regionkey, r_name, 0 AS level
    FROM region
    WHERE r_regionkey = 1
    UNION ALL
    SELECT r.r_regionkey, r.r_name, rh.level + 1
    FROM region r
    JOIN region_hierarchy rh ON r.r_regionkey = rh.r_regionkey + 1
),
orders_summary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
customer_aggregate AS (
    SELECT c.c_custkey, c.c_mktsegment, SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count,
           ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(o.o_totalprice) DESC) AS rn
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_mktsegment
),
part_supplier_info AS (
    SELECT p.p_partkey, p.p_name, s.s_suppkey, s.s_name,
           ps.ps_availqty, ps.ps_supplycost, 
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),
final_summary AS (
    SELECT pa.p_name, pa.ps_availqty, pa.ps_supplycost, 
           COALESCE(ca.total_spent, 0) AS customer_spending,
           (SELECT AVG(total_revenue) FROM orders_summary) AS avg_revenue
    FROM part_supplier_info pa
    LEFT JOIN customer_aggregate ca ON pa.p_partkey = ca.c_custkey
    WHERE pa.rank = 1
)
SELECT r.r_name, fs.p_name, fs.ps_availqty, fs.ps_supplycost, fs.customer_spending,
       CASE WHEN fs.customer_spending > fs.avg_revenue THEN 'Above Average' ELSE 'Below Average' END AS spending_category
FROM region_hierarchy r
JOIN final_summary fs ON r.r_regionkey = (SELECT MAX(n.n_regionkey) FROM nation n JOIN supplier s ON n.n_nationkey = s.s_nationkey WHERE s.s_suppkey = fs.ps_supplierid)
WHERE fs.ps_supplycost IS NOT NULL
ORDER BY r.r_name, fs.customer_spending DESC;
