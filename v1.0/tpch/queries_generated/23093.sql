WITH RECURSIVE supplier_parts AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, p.p_mfgr, 
           ps.ps_availqty, ps.ps_supplycost, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY ps.ps_supplycost DESC) as rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 0
),
ranked_parts AS (
    SELECT s_partkey, s_name, p_name, p_mfgr, ps_availqty, ps_supplycost,
           COALESCE(ps_availqty, 0) AS available_quantity,
           CASE WHEN s_suppkey % 2 = 0 THEN 'Even' ELSE 'Odd' END AS supp_key_type
    FROM supplier_parts
    WHERE rank <= 5
),
order_details AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, 
           l.l_partkey, l.l_quantity, l.l_discount, l.l_tax,
           SUM(l.l_extendedprice) OVER (PARTITION BY o.o_orderkey) AS total_extended_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_discount BETWEEN 0 AND 0.1 AND 
          o.o_orderstatus NOT LIKE 'F'
),
customer_summary AS (
    SELECT c.c_custkey, c.c_name, 
           COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT r.n_name, rp.p_name, 
       SUM(od.total_extended_price * (1 - rp.ps_supplycost / NULLIF(rp.available_quantity, 0))) AS adjusted_revenue,
       cs.order_count, cs.total_spent,
       CASE WHEN cs.order_count IS NULL THEN 'No Orders' ELSE 'Has Orders' END AS order_status
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier_parts sp ON n.n_nationkey = sp.s_suppkey
JOIN ranked_parts rp ON sp.p_partkey = rp.p_partkey
JOIN order_details od ON rp.p_partkey = od.l_partkey
LEFT JOIN customer_summary cs ON od.o_orderkey = cs.c_custkey
WHERE r.r_comment LIKE '%region%'
GROUP BY r.n_name, rp.p_name, cs.order_count, cs.total_spent
HAVING adjusted_revenue > 5000 OR COUNT(cs.c_custkey) > 10
ORDER BY adjusted_revenue DESC NULLS LAST;
