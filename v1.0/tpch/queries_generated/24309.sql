WITH RECURSIVE nation_count AS (
    SELECT n.n_nationkey, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey
),
part_info AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_avail_qty, 
           AVG(ps.ps_supplycost) AS avg_supplycost, 
           MAX(p.p_retailprice) * COALESCE(NULLIF(SUM(l.l_quantity), 0), 1) AS price_qty_ratio
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey 
    GROUP BY p.p_partkey, p.p_name
),
filtered_orders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice,
           SUM(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice ELSE 0 END) AS total_discounted_price
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_custkey, o.o_totalprice
),
ranked_info AS (
    SELECT p.*, ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.total_avail_qty DESC) AS rn
    FROM part_info p
    WHERE price_qty_ratio > (SELECT AVG(price_qty_ratio) FROM part_info)
)
SELECT n.n_name, COUNT(DISTINCT o.o_orderkey) AS total_orders, 
       SUM(o.total_discounted_price) AS total_discounted_value, 
       SUM(r.price_qty_ratio) AS sum_price_qty_ratio
FROM nation n
JOIN filtered_orders o ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = o.o_custkey)
LEFT JOIN ranked_info r ON r.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = n.n_nationkey))
WHERE n.n_nationkey IS NOT NULL
GROUP BY n.n_name
HAVING SUM(o.total_discounted_value) > (SELECT AVG(total_discounted_price) FROM filtered_orders)
ORDER BY total_orders DESC, n.n_name ASC;
