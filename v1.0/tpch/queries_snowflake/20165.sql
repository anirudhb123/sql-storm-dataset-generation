
WITH RECURSIVE supplier_agg AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
ranked_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           RANK() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
),
customer_orders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
active_customers AS (
    SELECT co.c_custkey, co.total_spent
    FROM customer_orders co
    WHERE co.total_spent > (SELECT AVG(total_spent) FROM customer_orders)
),
qualified_suppliers AS (
    SELECT s.s_name, s.s_nationkey, sa.total_supplycost
    FROM supplier s
    JOIN supplier_agg sa ON s.s_suppkey = sa.s_suppkey
    WHERE sa.total_supplycost > (SELECT AVG(total_supplycost) FROM supplier_agg)
),
order_details AS (
    SELECT o.o_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice,
           l.l_discount, l.l_tax,
           RANK() OVER (PARTITION BY o.o_orderkey ORDER BY l.l_extendedprice DESC) AS item_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_discount > 0.1
)
SELECT rc.r_name, COUNT(DISTINCT ac.c_custkey) AS active_customer_count,
       SUM(od.l_extendedprice * (1 - od.l_discount)) AS total_revenue,
       AVG(od.l_tax) AS average_tax
FROM region rc
LEFT JOIN nation n ON rc.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN qualified_suppliers qs ON s.s_suppkey = qs.s_nationkey
LEFT JOIN active_customers ac ON ac.c_custkey = (
    SELECT c.c_custkey 
    FROM customer c
    WHERE c.c_nationkey = n.n_nationkey
    ORDER BY c.c_acctbal DESC 
    LIMIT 1
)
LEFT JOIN order_details od ON ac.c_custkey = od.o_orderkey
WHERE qs.total_supplycost IS NOT NULL 
  AND qs.total_supplycost > 1000 
  AND od.item_rank <= 3
GROUP BY rc.r_name
HAVING COUNT(DISTINCT ac.c_custkey) > 0
ORDER BY total_revenue DESC, active_customer_count DESC;
