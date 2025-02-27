WITH RECURSIVE top_nations AS (
    SELECT n_nationkey, n_name, n_regionkey, ROW_NUMBER() OVER (PARTITION BY n_regionkey ORDER BY COUNT(s_suppkey) DESC) AS rn
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n_nationkey, n_name, n_regionkey
),
product_availability AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, SUM(ps.ps_availqty) AS total_available
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
),
recent_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY o.o_orderkey, o.o_orderdate
),
supplier_details AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, 
           CASE 
               WHEN s.s_acctbal IS NULL THEN 'No Balance' 
               ELSE TO_CHAR(s.s_acctbal, 'FM$999,999.00') 
           END AS formatted_balance
    FROM supplier s
    WHERE s.s_acctbal > 1000
),
nation_summary AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
           AVG(s.s_acctbal) AS avg_acctbal, 
           MAX(s.s_acctbal) AS max_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
)
SELECT 
    p.p_name,
    pa.total_available,
    COALESCE(ro.total_revenue, 0) AS revenue_last_30_days,
    ns.n_name,
    ns.supplier_count,
    ns.avg_acctbal,
    sd.formatted_balance,
    nt.rn AS nation_rank
FROM product_availability pa
LEFT JOIN recent_orders ro ON pa.p_partkey = (SELECT l.l_partkey FROM lineitem l
                                                WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o 
                                                                       WHERE o.o_orderstatus = 'O')
                                                LIMIT 1)
JOIN nation_summary ns ON pa.p_brand = ns.n_name
JOIN supplier_details sd ON ns.supplier_count > 0
JOIN top_nations nt ON ns.n_name = nt.n_name
WHERE pa.total_available > 50
ORDER BY pa.total_available DESC, revenue_last_30_days DESC;
