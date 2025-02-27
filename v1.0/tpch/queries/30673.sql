WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    INNER JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
part_supplier_counts AS (
    SELECT ps.ps_partkey, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
order_totals AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1995-01-01'
    GROUP BY o.o_orderkey
),
ranked_orders AS (
    SELECT o.o_orderkey, total_price,
           RANK() OVER (ORDER BY total_price DESC) AS price_rank
    FROM order_totals o
)
SELECT
    p.p_partkey,
    p.p_name,
    p.p_brand,
    SUM(l.l_quantity) AS total_quantity,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
    ns.n_name AS supplier_nation,
    sc.supplier_count,
    r.total_price AS highest_order_total,
    CASE 
        WHEN COUNT(l.l_orderkey) > 0 THEN 'Supplied'
        ELSE 'Not Supplied'
    END AS supply_status
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN nation ns ON s.s_nationkey = ns.n_nationkey
LEFT JOIN part_supplier_counts sc ON p.p_partkey = sc.ps_partkey
LEFT JOIN ranked_orders r ON l.l_orderkey = r.o_orderkey
WHERE p.p_size BETWEEN 20 AND 30
  AND p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
GROUP BY p.p_partkey, p.p_name, p.p_brand, ns.n_name, sc.supplier_count, r.total_price
HAVING SUM(l.l_quantity) > 100
ORDER BY total_revenue DESC
LIMIT 10;