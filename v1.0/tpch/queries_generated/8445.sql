WITH ranked_nations AS (
    SELECT n.n_name, SUM(s.s_acctbal) AS total_acctbal, RANK() OVER (ORDER BY SUM(s.s_acctbal) DESC) AS rank
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
top_nations AS (
    SELECT n_name
    FROM ranked_nations
    WHERE rank <= 5
),
high_value_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_mktsegment
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_totalprice > 1000
)
SELECT pn.p_name, SUM(li.l_extendedprice * (1 - li.l_discount)) AS revenue
FROM part pn
JOIN lineitem li ON pn.p_partkey = li.l_partkey
JOIN high_value_orders hvo ON li.l_orderkey = hvo.o_orderkey
JOIN customer c ON hvo.o_custkey = c.c_custkey
JOIN supplier s ON c.c_nationkey = s.s_nationkey
JOIN ranked_nations rn ON s.s_nationkey = rn.n_nationkey
WHERE rn.n_name IN (SELECT n_name FROM top_nations)
GROUP BY pn.p_name
ORDER BY revenue DESC;
