WITH RECURSIVE top_suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal = (SELECT MAX(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ts.level + 1
    FROM supplier s
    JOIN top_suppliers ts ON s.s_acctbal > ts.s_acctbal
    WHERE ts.level < 5
),
order_totals AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
supplier_parts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_avail_qty
    FROM partsupp ps
    JOIN top_suppliers ts ON ps.ps_suppkey = ts.s_suppkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
nation_sales AS (
    SELECT n.n_nationkey, SUM(ot.total_price) AS sales_total
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN order_totals ot ON o.o_orderkey = ot.o_orderkey
    GROUP BY n.n_nationkey
)
SELECT r.r_name, ns.sales_total, COUNT(sp.ps_partkey) AS part_count,
       CASE WHEN ns.sales_total IS NULL THEN 'No Sales' ELSE 'Sales Present' END AS sales_status
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN nation_sales ns ON n.n_nationkey = ns.n_nationkey
LEFT JOIN supplier_parts sp ON n.n_nationkey = sp.ps_partkey
GROUP BY r.r_name, ns.sales_total
HAVING ns.sales_total > 10000 OR ns.sales_total IS NULL
ORDER BY r.r_name, sales_total DESC;
