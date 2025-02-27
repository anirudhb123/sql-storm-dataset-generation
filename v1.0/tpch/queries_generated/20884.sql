WITH RECURSIVE supplier_chain AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s2.s_suppkey, s2.s_name, s2.s_address, s2.s_nationkey, s2.s_acctbal
    FROM supplier s2
    JOIN supplier_chain sc ON sc.s_nationkey = s2.s_nationkey
    WHERE s2.s_acctbal > sc.s_acctbal
), 
mean_prices AS (
    SELECT p.p_partkey, AVG(ps.ps_supplycost) as avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
), 
high_value_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, CUME_DIST() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM orders o 
    WHERE o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderstatus = o.o_orderstatus)
), 
order_line_stats AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
), 
nation_info AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS suppliers_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    ni.n_name,
    COUNT(DISTINCT sc.s_suppkey) AS total_suppliers,
    AVG(mp.avg_supply_cost) AS average_supply_cost,
    SUM(ols.total_revenue) AS total_revenue,
    CASE WHEN SUM(ols.total_revenue) IS NULL THEN 'No Revenue' 
         ELSE 'Revenue Exists' END AS revenue_status
FROM nation_info ni
LEFT JOIN supplier_chain sc ON ni.n_nationkey = sc.s_nationkey
LEFT JOIN mean_prices mp ON mp.p_partkey IN (SELECT ps.p_partkey 
                                              FROM partsupp ps 
                                              JOIN lineitem l ON l.l_orderkey = ps.ps_partkey)
LEFT JOIN order_line_stats ols ON ols.l_orderkey IN (SELECT o.o_orderkey 
                                                      FROM high_value_orders o
                                                      WHERE o.order_rank <= 0.1)
GROUP BY ni.n_name
HAVING COUNT(DISTINCT sc.s_suppkey) > 0 AND AVG(mp.avg_supply_cost) IS NOT NULL
ORDER BY total_revenue DESC NULLS LAST;
