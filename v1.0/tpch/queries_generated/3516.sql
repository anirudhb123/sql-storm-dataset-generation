WITH supplier_totals AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
customer_orders AS (
    SELECT c.c_custkey,
           c.c_name,
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
ranked_nations AS (
    SELECT n.n_nationkey,
           n.n_name,
           DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT s.s_suppkey) DESC) AS nation_rank
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT c.c_name,
       coalesce(ct.order_count, 0) AS order_count,
       coalesce(ct.total_spent, 0.00) AS total_spent,
       st.total_supply_cost AS supplier_cost,
       rn.n_name AS nation_name,
       rn.nation_rank
FROM customer_orders ct
FULL OUTER JOIN supplier_totals st ON ct.order_count > 0
JOIN ranked_nations rn ON rn.n_nationkey = (SELECT n.n_nationkey
                                             FROM nation n
                                             JOIN customer c ON n.n_nationkey = c.c_nationkey
                                             WHERE c.c_custkey = ct.c_custkey
                                             LIMIT 1)
ORDER BY rn.nation_rank, ct.total_spent DESC;
