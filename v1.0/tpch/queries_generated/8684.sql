WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation, r.r_name AS region, 1 AS level
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE s.s_acctbal > 10000

    UNION ALL

    SELECT sh.s_suppkey, sh.s_name, sh.s_acctbal, n.n_name AS nation, r.r_name AS region, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN nation n ON ps.ps_suppkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE ps.ps_availqty > 50
)
SELECT s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM orders o
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN supplier_hierarchy s ON c.c_nationkey = s.nation
WHERE o.o_orderdate BETWEEN '2022-01-01' AND '2023-01-01'
GROUP BY s.s_name
HAVING total_revenue > 50000
ORDER BY total_revenue DESC
LIMIT 10;
