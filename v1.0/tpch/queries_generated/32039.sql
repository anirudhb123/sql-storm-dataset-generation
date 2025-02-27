WITH RECURSIVE top_suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal * 0.9
    FROM supplier s
    JOIN top_suppliers ts ON s.s_acctbal < ts.s_acctbal
),
order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           SUM(l.l_discount) AS total_discount, COUNT(DISTINCT l.l_partkey) AS parts_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
nation_region AS (
    SELECT n.n_name, r.r_name, COUNT(DISTINCT s.s_suppkey) AS suppliers_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name, r.r_name
)
SELECT p.p_name, ns.n_name, ns.r_name, ts.s_name, os.total_revenue,
       os.total_discount, os.parts_count
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN top_suppliers ts ON ts.s_suppkey = s.s_suppkey
JOIN order_summary os ON os.parts_count > 2
LEFT JOIN nation_region ns ON ns.suppliers_count > 5 AND 
     (ns.n_name IS NOT NULL OR ns.r_name IS NOT NULL)
WHERE p.p_retailprice > (
    SELECT AVG(p2.p_retailprice)
    FROM part p2
    WHERE p2.p_type LIKE 'type%'
)
ORDER BY os.total_revenue DESC
LIMIT 100;
