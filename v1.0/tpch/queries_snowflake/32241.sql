
WITH RECURSIVE part_supplier AS (
    SELECT ps.ps_partkey, s.s_suppkey, s.s_name, ps.ps_availqty, ps.ps_supplycost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE ps.ps_availqty > 50

    UNION ALL

    SELECT ps.ps_partkey, s.s_suppkey, s.s_name, ps.ps_availqty, ps.ps_supplycost
    FROM part_supplier psu
    JOIN partsupp ps ON psu.ps_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE ps.ps_availqty < psu.ps_availqty
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
ranked_suppliers AS (
    SELECT ps_partkey, s_suppkey, s.s_name, ps_availqty, ps_supplycost,
           RANK() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost DESC) AS rank_order
    FROM part_supplier
),
nation_summary AS (
    SELECT n.n_nationkey, n.n_name, COUNT(s.s_suppkey) AS supplier_count,
           AVG(s.s_acctbal) AS avg_account_balance
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT r.r_name, COUNT(DISTINCT ns.n_nationkey) AS nation_count,
       SUM(co.order_count) AS total_orders,
       AVG(co.total_spent) AS avg_spent_per_customer,
       LISTAGG(DISTINCT CONCAT(s.s_name, ' (', ps.ps_availqty, ' available)')) WITHIN GROUP (ORDER BY s.s_name) AS supplier_details
FROM region r
LEFT JOIN nation_summary ns ON r.r_regionkey = ns.n_nationkey
LEFT JOIN customer_orders co ON ns.n_nationkey = co.c_custkey
LEFT JOIN ranked_suppliers ps ON ps.ps_partkey IN (SELECT DISTINCT p.p_partkey FROM part p)
LEFT JOIN supplier s ON ps.s_suppkey = s.s_suppkey
WHERE ns.supplier_count > 10 AND co.total_spent IS NOT NULL
GROUP BY r.r_name
HAVING COUNT(DISTINCT ns.n_nationkey) > 1
ORDER BY nation_count DESC, avg_spent_per_customer DESC;
