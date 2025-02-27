WITH RECURSIVE cte_supplier_orders AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_acctbal,
           COALESCE(o.o_orderkey, 0) AS related_order,
           CASE WHEN o.o_orderkey IS NOT NULL THEN o.o_totalprice ELSE 0 END AS order_total
    FROM supplier s
    LEFT JOIN orders o ON s.s_suppkey % 100 = o.o_custkey % 100
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 0

    UNION ALL

    SELECT s.s_suppkey,
           s.s_name,
           s.s_acctbal,
           COALESCE(l.l_orderkey, 0) AS related_order,
           CASE WHEN l.l_orderkey IS NOT NULL THEN SUM(l.l_extendedprice * (1 - l.l_discount)) ELSE 0 END AS order_total
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
)

SELECT r.r_name AS region_name,
       nt.n_name AS nation_name,
       SUM(cnt.total_spent) AS total_spent,
       MAX(s.acct_balance) AS max_acct_balance
FROM (
    SELECT DISTINCT o.o_custkey, 
           SUM(o.o_totalprice) FILTER (WHERE o.o_orderstatus = 'O') AS total_spent,
           c.c_nationkey
    FROM orders o
    LEFT JOIN customer c ON o.o_custkey = c.c_custkey
    GROUP BY o.o_custkey, c.c_nationkey
) AS cnt
JOIN nation nt ON cnt.c_nationkey = nt.n_nationkey
JOIN region r ON nt.n_regionkey = r.r_regionkey
JOIN cte_supplier_orders s ON s.related_order = cnt.o_custkey
HAVING avg(s.order_total) > (SELECT AVG(ps_supplycost) FROM partsupp) + 1000
GROUP BY r.r_name, nt.n_name
ORDER BY total_spent DESC, region_name, nation_name;
