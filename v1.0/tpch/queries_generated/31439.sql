WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.level * 500
),
customer_summary AS (
    SELECT c.c_nationkey, COUNT(DISTINCT c.c_custkey) AS customer_count,
           AVG(c.c_acctbal) AS avg_acctbal
    FROM customer c
    GROUP BY c.c_nationkey
),
part_supplier AS (
    SELECT p.p_partkey, p.p_name,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
ranked_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           DENSE_RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
),
joined_data AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity,
           p.p_name, c.c_name, o.o_totalprice, o.o_orderdate,
           n.n_name AS nation_name,
           COALESCE(sh.level, -1) AS supplier_level
    FROM lineitem l
    JOIN part p ON l.l_partkey = p.p_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN supplier_hierarchy sh ON l.l_suppkey = sh.s_suppkey
)
SELECT jd.nation_name, COUNT(DISTINCT jd.l_orderkey) AS order_count,
       SUM(jd.l_quantity) AS total_quantity,
       AVG(jd.o_totalprice) AS avg_order_value,
       PS.total_cost, PS.supplier_count,
       C.customer_count, C.avg_acctbal
FROM joined_data jd
JOIN part_supplier PS ON jd.l_partkey = PS.p_partkey
JOIN customer_summary C ON jd.nation_name = C.c_nationkey
WHERE jd.o_orderdate >= '2022-01-01' AND jd.o_orderdate < '2023-01-01'
GROUP BY jd.nation_name, PS.total_cost, PS.supplier_count, C.customer_count, C.avg_acctbal
ORDER BY order_count DESC, avg_order_value DESC;
