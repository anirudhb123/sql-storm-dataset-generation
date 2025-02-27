WITH RECURSIVE part_ranked AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, 
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_price
    FROM part p
),
supplier_stats AS (
    SELECT s.s_suppkey, SUM(ps.ps_availqty) AS total_avail_qty, 
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
sub_order AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           CASE WHEN o.o_orderstatus = 'F' THEN 'Fulfilled' ELSE 'Pending' END AS status
    FROM orders o
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
),
line_item_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue, 
           COUNT(*) as line_count,
           MAX(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returns
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT r.r_name, SUM(ls.revenue) AS total_revenue, 
       COUNT(DISTINCT so.o_orderkey) AS total_orders,
       COALESCE(s.total_avail_qty, 0) AS supplier_avail_qty,
       COALESCE(ss.avg_supply_cost, 0) AS avg_supply_cost
FROM region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN supplier_stats ss ON ss.s_suppkey = s.s_suppkey
JOIN sub_order so ON EXISTS (
    SELECT 1 FROM line_item_summary ls 
    WHERE ls.l_orderkey = so.o_orderkey
    HAVING COUNT(ls.line_count) > 5
)
JOIN line_item_summary ls ON ls.l_orderkey = so.o_orderkey
LEFT JOIN part_ranked pr ON pr.rank_price <= 10
WHERE pr.p_brand IS NOT NULL OR pr.p_name IS NOT NULL
GROUP BY r.r_name
HAVING SUM(ls.revenue) > 1000000 AND COUNT(DISTINCT so.o_orderkey) > 50
ORDER BY total_revenue DESC, r.r_name;
