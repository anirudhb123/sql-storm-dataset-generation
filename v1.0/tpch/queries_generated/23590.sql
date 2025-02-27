WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_nationkey = 1
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
), 
order_totals AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
supplier_aggregates AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
totals AS (
    SELECT n.n_name, 
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           AVG(ot.total_price) AS avg_order_value,
           COUNT(s.s_suppkey) AS supplier_count,
           SUM(s.s_acctbal) AS total_supplier_balance,
           MAX(s.s_acctbal) AS max_supplier_balance
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN order_totals ot ON o.o_orderkey = ot.o_orderkey
    LEFT JOIN partsupp ps ON ps.ps_partkey IN (SELECT DISTINCT l.l_partkey 
                                                FROM lineitem l 
                                                JOIN order_totals ot ON l.l_orderkey = ot.o_orderkey
                                                WHERE ot.total_price IS NOT NULL)
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE COALESCE(o.o_orderstatus, 'F') <> 'F'
      AND (n.n_name IS NOT NULL OR n.n_regionkey IS NULL)
    GROUP BY n.n_name
)
SELECT n.n_name, 
       COALESCE(t.order_count, 0) AS order_count, 
       COALESCE(t.avg_order_value, 0.00) AS avg_order_value,
       t.supplier_count,
       t.total_supplier_balance,
       CASE WHEN t.supplier_count > 0 THEN t.total_supplier_balance / t.supplier_count ELSE NULL END AS avg_supplier_balance 
FROM nation n
LEFT JOIN totals t ON n.n_name = t.n_name
WHERE (EXISTS (SELECT 1 FROM nation_hierarchy nh WHERE nh.n_name = n.n_name) OR t.supplier_count > 5)
ORDER BY n.n_name DESC NULLS LAST;
