WITH nation_supplier AS (
    SELECT n.n_name, SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
customer_order AS (
    SELECT c.c_nationkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_nationkey
),
lineitem_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN DATE '2021-01-01' AND DATE '2021-12-31'
    GROUP BY l.l_orderkey
)
SELECT ns.n_name, ns.total_acctbal, co.order_count, SUM(ls.total_revenue) AS total_revenue
FROM nation_supplier ns
JOIN customer_order co ON ns.n_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = co.c_nationkey)
LEFT JOIN lineitem_summary ls ON ls.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = co.c_nationkey))
GROUP BY ns.n_name, ns.total_acctbal, co.order_count
ORDER BY ns.total_acctbal DESC, total_revenue DESC;
