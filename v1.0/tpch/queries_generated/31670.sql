WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size > 20 AND p.p_retailprice < 500
)

SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(o.o_totalprice) AS total_revenue,
    AVG(l.l_discount) AS avg_discount,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(o.o_totalprice) DESC) AS revenue_rank
FROM region r
JOIN nation n ON n.n_regionkey = r.r_regionkey
JOIN supplier_hierarchy sh ON sh.s_nationkey = n.n_nationkey
JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN lineitem l ON l.l_partkey = p.p_partkey
JOIN orders o ON o.o_orderkey = l.l_orderkey
JOIN customer c ON c.c_custkey = o.o_custkey
WHERE o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
GROUP BY r.r_name, n.n_name
HAVING SUM(o.o_totalprice) > 10000
ORDER BY region_name, total_revenue DESC;
