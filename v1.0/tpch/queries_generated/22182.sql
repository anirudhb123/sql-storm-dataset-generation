WITH RECURSIVE supplier_agg AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost 
    FROM supplier s 
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    GROUP BY s.s_suppkey, s.s_name 
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 0
    UNION ALL 
    SELECT s.s_suppkey, 
           s.s_name, 
           sa.total_supply_cost + SUM(ps.ps_supplycost * ps.ps_availqty) 
    FROM supplier_agg sa
    JOIN supplier s ON s.s_suppkey = sa.s_suppkey 
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    WHERE sa.total_supply_cost IS NOT NULL
    GROUP BY s.s_suppkey, s.s_name
), 
nation_region AS (
    SELECT n.n_nationkey, 
           r.r_regionkey, 
           COUNT(n.n_nationkey) AS nation_count 
    FROM nation n 
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey 
    GROUP BY n.n_nationkey, r.r_regionkey 
    HAVING COUNT(n.n_nationkey) >= 1
), 
customer_orders AS (
    SELECT c.c_custkey, 
           SUM(CASE WHEN o.o_orderstatus = 'O' THEN o.o_totalprice ELSE 0 END) AS open_order_total, 
           COUNT(DISTINCT o.o_orderkey) AS total_orders 
    FROM customer c 
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey 
    GROUP BY c.c_custkey 
    HAVING SUM(o.o_totalprice) IS NOT DISTINCT FROM SUM(CASE WHEN o.o_orderstatus = 'O' THEN o.o_totalprice END)
), 
lineitem_summary AS (
    SELECT l.l_orderkey, 
           l.l_partkey, 
           l.l_suppkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue, 
           ROW_NUMBER() OVER (PARTITION BY l.l_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank 
    FROM lineitem l 
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey 
    WHERE l.l_returnflag = 'N' 
    GROUP BY l.l_orderkey, l.l_partkey, l.l_suppkey 
), 
critical_parts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           MAX(ps.ps_supplycost) AS max_supply_cost 
    FROM part p 
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey 
    WHERE p.p_size IS NOT NULL 
    GROUP BY p.p_partkey, p.p_name 
    HAVING MAX(ps.ps_supplycost) IS NOT NULL 
    ORDER BY max_supply_cost DESC 
    LIMIT 10
)
SELECT n.n_name, 
       SUM(c.open_order_total) AS cumulative_revenue, 
       STRING_AGG(DISTINCT p.p_name, ', ') AS part_names, 
       SUM(l.net_revenue) AS total_sales 
FROM nation n 
JOIN nation_region nr ON n.n_nationkey = nr.n_nationkey 
JOIN customer_orders c ON c.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey LIMIT 1) 
LEFT JOIN lineitem_summary l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey) 
LEFT JOIN critical_parts p ON p.p_partkey = (SELECT pp.p_partkey FROM part pp WHERE pp.p_size < 100 ORDER BY RANDOM() LIMIT 1) 
GROUP BY n.n_name
HAVING COUNT(DISTINCT c.c_custkey) > 1 OR SUM(c.open_order_total) IS NULL
ORDER BY cumulative_revenue DESC;
