WITH top_nations AS (
    SELECT n.n_nationkey, n.n_name, SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
    ORDER BY total_acctbal DESC
    LIMIT 5
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
lineitem_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
),
part_supplier AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost) AS total_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)

SELECT 
    cn.n_name,
    co.c_name,
    co.order_count,
    co.total_spent,
    ps.p_name,
    ps.total_supplycost,
    ls.net_revenue
FROM top_nations cn
JOIN customer_orders co ON co.order_count > 0
JOIN part_supplier ps ON ps.total_supplycost < 1000
JOIN lineitem_summary ls ON ls.net_revenue > 5000
WHERE cn.n_nationkey IN (SELECT c.c_nationkey FROM customer c WHERE c.custkey = co.c_custkey)
ORDER BY cn.total_acctbal DESC, co.total_spent DESC;
