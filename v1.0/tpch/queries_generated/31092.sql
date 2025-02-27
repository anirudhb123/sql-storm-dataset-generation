WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_discount > 0.1 AND sh.level < 5
),
order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_shipdate > '2023-01-01'
    GROUP BY o.o_orderkey
),
ranked_customers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
nation_summary AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
)
SELECT ns.n_name, ns.supplier_count, rc.c_name, rc.total_spent, sh.level,
       COALESCE(os.total_revenue, 0) AS order_revenue
FROM nation_summary ns
JOIN ranked_customers rc ON ns.supplier_count > 10
LEFT JOIN order_summary os ON rc.c_custkey = os.o_orderkey
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = rc.c_nationkey
WHERE rc.rank <= 5
ORDER BY ns.n_name, rc.total_spent DESC;
