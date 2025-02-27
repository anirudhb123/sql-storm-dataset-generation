WITH RECURSIVE supplier_recursive AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sr.level + 1
    FROM supplier s
    JOIN supplier_recursive sr ON s.s_nationkey = sr.s_nationkey
    WHERE s.s_acctbal > 5000 AND sr.level < 5
),
high_value_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderstatus, o.o_shippriority
    FROM orders o
    WHERE o.o_totalprice > (
        SELECT AVG(o2.o_totalprice) 
        FROM orders o2
    )
),
part_supplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost,
           RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost) AS rnk
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
nation_supplier AS (
    SELECT n.n_nationkey, n.n_name, s.s_suppkey, s.s_name
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
),
order_lines AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_extendedprice, l.l_discount,
           CASE WHEN l.l_discount > 0.1 THEN 'High Discount' ELSE 'Low Discount' END AS Discount_Category
    FROM lineitem l
)
SELECT ns.n_nationkey, ns.n_name, COALESCE(sr.s_name, 'No Supplier') AS supplier_name,
       SUM(ol.l_extendedprice * (1 - ol.l_discount)) AS total_sales,
       SUM(ps.ps_availqty) AS total_avail_qty, COUNT(DISTINCT ho.o_orderkey) AS order_count
FROM nation_supplier ns
LEFT JOIN supplier_recursive sr ON ns.s_suppkey = sr.s_suppkey
JOIN order_lines ol ON ol.l_orderkey IN (
    SELECT o.o_orderkey
    FROM high_value_orders ho
    WHERE ho.o_orderstatus = 'F'
)
JOIN part_supplier ps ON ol.l_partkey = ps.p_partkey AND ps.rnk = 1
GROUP BY ns.n_nationkey, ns.n_name, sr.s_name
HAVING SUM(ol.l_extendedprice * (1 - ol.l_discount)) > 10000
ORDER BY total_sales DESC NULLS LAST;
