
WITH top_suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    WHERE s.s_acctbal > 0
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           (SELECT COUNT(*) FROM supplier ss WHERE ss.s_acctbal > s.s_acctbal) + 1 AS rank
    FROM supplier s
    JOIN top_suppliers ts ON s.s_suppkey > ts.s_suppkey
    WHERE ts.rank < 10
),
order_summary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
),
nation_customers AS (
    SELECT c.c_custkey, n.n_nationkey, n.n_name, c.c_acctbal,
           CASE WHEN c.c_acctbal IS NULL THEN 'No Balance' 
                WHEN c.c_acctbal < 1000 THEN 'Low Balance' 
                ELSE 'Sufficient Balance' END AS balance_category
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
),
aggregated_revenue AS (
    SELECT n.n_name, SUM(os.total_revenue) AS total_revenue
    FROM order_summary os
    JOIN nation_customers nc ON os.o_custkey = nc.c_custkey
    JOIN nation n ON nc.n_nationkey = n.n_nationkey
    GROUP BY n.n_name
),
supplier_parts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey
)
SELECT ts.s_name, n.n_name, SUM(ar.total_revenue) AS national_revenue,
       SUM(sp.total_available) AS total_available_parts,
       CASE WHEN SUM(sp.total_available) > 1000 THEN 'High Supply' 
            ELSE 'Low Supply' END AS supply_status
FROM top_suppliers ts
JOIN supplier_parts sp ON ts.s_suppkey = sp.ps_suppkey
JOIN aggregated_revenue ar ON ts.s_suppkey = ar.total_revenue
JOIN nation n ON n.n_nationkey = ts.s_suppkey
GROUP BY ts.s_name, n.n_name
HAVING SUM(ar.total_revenue) > 10000 OR 
       (SUM(sp.total_available) > 1000 AND 'High Supply' = 'High Supply')
ORDER BY national_revenue DESC;
