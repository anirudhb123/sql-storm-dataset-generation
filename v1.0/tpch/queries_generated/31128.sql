WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL AND s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (sh.s_acctbal * 0.9)
),
part_supplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, s.s_name, s.s_acctbal
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate, ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
),
order_summary AS (
    SELECT co.o_orderkey, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales
    FROM customer_orders co
    JOIN lineitem li ON co.o_orderkey = li.l_orderkey
    GROUP BY co.o_orderkey
),
top_sales AS (
    SELECT o.o_orderkey, os.total_sales, ROW_NUMBER() OVER (ORDER BY os.total_sales DESC) AS sales_rank
    FROM orders o
    JOIN order_summary os ON o.o_orderkey = os.o_orderkey
    WHERE os.total_sales > 1000
)
SELECT r.r_name, COUNT(DISTINCT ns.n_nationkey) AS nations_count, SUM(p.ps_supplycost) AS total_supplycost, AVG(s.s_acctbal) AS avg_acctbal, 
       STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_acctbal, ')'), '; ') AS suppliers_info
FROM region r
LEFT JOIN nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN supplier_hierarchy sh ON ns.n_nationkey = sh.s_nationkey
LEFT JOIN part_supplier p ON p.s_name = sh.s_name
JOIN top_sales ts ON ts.o_orderkey = p.p_partkey
GROUP BY r.r_name
HAVING COUNT(DISTINCT ns.n_nationkey) > 1 AND AVG(s.s_acctbal) IS NOT NULL
ORDER BY total_supplycost DESC
LIMIT 10;
