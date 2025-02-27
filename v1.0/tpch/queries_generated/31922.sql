WITH RECURSIVE order_dates AS (
    SELECT o_orderkey, o_orderdate, o_totalprice
    FROM orders
    WHERE o_orderdate >= DATE '2023-01-01'
    UNION ALL
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM orders o
    INNER JOIN order_dates od ON o.o_orderkey = od.o_orderkey
    WHERE o.o_orderdate > od.o_orderdate
),
supplier_totals AS (
    SELECT ps.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.s_suppkey
),
customer_stats AS (
    SELECT c.c_custkey, AVG(o.o_totalprice) AS avg_order_value, SUM(o.o_totalprice) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
ranked_nations AS (
    SELECT n.n_nationkey, n.n_name,
           ROW_NUMBER() OVER (ORDER BY SUM(s.s_acctbal) DESC) AS nation_rank
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT p.p_name, r.n_name AS supplier_nation, c.c_name AS customer_name, 
       es.supplier_cost, od.o_orderdate, od.o_totalprice,
       ROW_NUMBER() OVER (PARTITION BY r.n_name ORDER BY od.o_totalprice DESC) AS order_rank
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier_totals es ON ps.ps_suppkey = es.s_suppkey
JOIN lineitem l ON l.l_partkey = p.p_partkey
JOIN orders od ON od.o_orderkey = l.l_orderkey
JOIN customer c ON c.c_custkey = od.o_custkey
JOIN ranked_nations r ON r.n_nationkey = (SELECT n.n_nationkey 
                                           FROM nation n 
                                           WHERE n.n_nationkey = c.c_nationkey)
WHERE od.o_totalprice > 1000
  AND p.p_retailprice IS NOT NULL
  AND es.total_cost IS NOT NULL
ORDER BY supplier_nation, order_rank
LIMIT 10;
