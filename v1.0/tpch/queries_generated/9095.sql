WITH nation_supplier AS (
    SELECT n.n_name, s.s_suppkey, s.s_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
),
part_supplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, p.p_retailprice, ps.ps_availqty, p.p_type
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
order_details AS (
    SELECT o.o_orderkey, o.o_orderdate, l.l_quantity, l.l_extendedprice, l.l_discount, l.l_tax
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
),
summary AS (
    SELECT ns.n_name, SUM(od.l_extendedprice * (1 - od.l_discount)) AS total_sales,
           COUNT(DISTINCT od.o_orderkey) AS order_count, SUM(ps.ps_availqty) AS total_available
    FROM nation_supplier ns
    JOIN part_supplier ps ON ns.s_suppkey = ps.ps_suppkey
    JOIN order_details od ON ps.ps_partkey = od.l_partkey
    GROUP BY ns.n_name
)
SELECT n_name, total_sales, order_count, total_available
FROM summary
WHERE total_sales > 10000
ORDER BY total_sales DESC, order_count DESC
LIMIT 10;
