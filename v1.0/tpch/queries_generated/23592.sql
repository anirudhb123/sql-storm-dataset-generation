WITH RECURSIVE customer_rank AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS rank_per_nation
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
), part_supplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost,
           RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) AS best_supplier
    FROM partsupp ps
    WHERE ps.ps_availqty > 0
), order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey
), high_value_orders AS (
    SELECT o.o_orderkey
    FROM order_summary o
    WHERE o.net_order_value > (
        SELECT AVG(net_order_value) FROM order_summary
    )
), nations_with_customers AS (
    SELECT n.n_nationkey, n.n_name, COUNT(c.c_custkey) AS customer_count
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_nationkey, n.n_name
    HAVING COUNT(c.c_custkey) > 0
), top_nations AS (
    SELECT r.r_regionkey, r.r_name, n.n_name, n.customer_count,
           ROW_NUMBER() OVER (ORDER BY n.customer_count DESC) AS nation_rank
    FROM nations_with_customers n
    JOIN region r ON n.n_nationkey = r.r_regionkey
)
SELECT p.p_partkey, p.p_name, p.p_brand, ps.ps_supplycost, ps.ps_availqty,
       COALESCE(AVG(l.l_discount), 0) AS average_discount, 
       COALESCE(MAX(l.l_shipdate), '1900-01-01') AS latest_ship_date,
       CASE WHEN c.rank_per_nation <= 5 THEN 'Top Customer' ELSE 'Regular Customer' END AS customer_status
FROM part p
LEFT JOIN part_supplier ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN lineitem l ON ps.ps_suppkey = l.l_suppkey
LEFT JOIN customer_rank c ON l.l_orderkey IN (SELECT o_orderkey FROM high_value_orders)
WHERE ps.best_supplier = 1 
  AND p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100)
GROUP BY p.p_partkey, p.p_name, p.p_brand, ps.ps_supplycost, ps.ps_availqty, c.rank_per_nation
ORDER BY p.p_brand ASC NULLS LAST, p.p_partkey DESC;
