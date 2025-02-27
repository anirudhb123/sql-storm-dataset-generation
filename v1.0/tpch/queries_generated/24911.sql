WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_comment, 0 AS level
    FROM supplier
    WHERE s_suppkey = (SELECT MIN(s_suppkey) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_comment, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON sh.s_nationkey = s.s_nationkey
    WHERE sh.level < 4
),
part_summary AS (
    SELECT p.p_partkey, p.p_name, 
           SUM(ps.ps_availqty * ps.ps_supplycost) AS total_cost,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
customer_order_summary AS (
    SELECT c.c_custkey, c.c_name, 
           COUNT(o.o_orderkey) AS total_orders,
           SUM(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice ELSE 0 END) AS fulfilled_value,
           SUM(CASE WHEN o.o_orderstatus <> 'F' THEN o.o_totalprice ELSE 0 END) AS unfulfilled_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
lineitem_summary AS (
    SELECT l.o_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_sales,
           AVG(l.l_quantity) AS avg_quantity,
           COUNT(l.l_orderkey) AS item_count
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '2022-01-01'
    GROUP BY l.o_orderkey
)
SELECT p.p_name, ps.total_cost, cs.total_orders, cs.fulfilled_value, cs.unfulfilled_value,
       ls.net_sales, ls.avg_quantity, ls.item_count
FROM part_summary ps
JOIN part p ON ps.p_partkey = p.p_partkey
LEFT JOIN customer_order_summary cs ON cs.total_orders > 0
LEFT JOIN lineitem_summary ls ON ls.o_orderkey = (SELECT MIN(o.o_orderkey)
                                                   FROM orders o
                                                   WHERE o.o_orderkey IN (SELECT l.o_orderkey
                                                                           FROM lineitem l
                                                                           WHERE l.l_partkey = p.p_partkey))
WHERE (ps.total_cost IS NOT NULL OR cs.fulfilled_value IS NOT NULL) 
  AND (cs.unfulfilled_value IS NULL OR cs.total_orders < 5)
ORDER BY ps.total_cost DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY
