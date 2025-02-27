WITH RECURSIVE sales_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_availqty, ps.ps_supplycost,
           (ps.ps_availqty * ps.ps_supplycost) AS total_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
    UNION ALL
    SELECT sh.s_suppkey, sh.s_name, sh.ps_availqty, sh.ps_supplycost,
           (sh.ps_availqty * sh.ps_supplycost) AS total_value
    FROM sales_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    WHERE sh.total_value < 10000
),
customer_order_summary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
ranked_customers AS (
    SELECT cus.c_custkey, cus.c_name, cus.total_spent,
           ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS rank
    FROM customer_order_summary cus
)
SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice,
       n.n_name AS nation_name, r.r_name AS region_name, 
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       AVG(s.s_acctbal) AS avg_supplier_balance
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN supplier s ON l.l_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT OUTER JOIN sales_hierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE p.p_retailprice > (
    SELECT AVG(p2.p_retailprice)
    FROM part p2
)
AND (sh.total_value IS NULL OR sh.total_value > 5000)
GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, 
         n.n_name, r.r_name
HAVING COUNT(DISTINCT l.l_orderkey) > 5
ORDER BY total_revenue DESC
FETCH FIRST 10 ROWS ONLY;
