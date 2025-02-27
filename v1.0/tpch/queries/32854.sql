WITH RECURSIVE supplier_cte AS (
    SELECT s_suppkey, s_name, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    
    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sc.level + 1
    FROM supplier s
    JOIN supplier_cte sc ON s.s_suppkey = sc.s_suppkey
    WHERE sc.level < 3
),
ranked_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1996-01-01'
),
lineitem_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS return_count
    FROM lineitem l
    GROUP BY l.l_orderkey
),
supplier_products AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    WHERE ps.ps_supplycost < (
        SELECT AVG(ps_supplycost) FROM partsupp
    )
    GROUP BY ps.ps_partkey
),
final_results AS (
    SELECT p.p_partkey, p.p_name, p.p_brand,
           sp.total_avail_qty, sp.avg_supply_cost,
           COALESCE(ls.total_revenue, 0) AS total_revenue,
           COALESCE(ls.return_count, 0) AS return_count,
           so.s_name AS supplier_name,
           RANK() OVER (ORDER BY COALESCE(ls.total_revenue, 0) DESC) AS revenue_rank
    FROM part p
    LEFT JOIN supplier_products sp ON p.p_partkey = sp.ps_partkey
    LEFT JOIN lineitem_summary ls ON ls.l_orderkey IN (
        SELECT o.o_orderkey
        FROM ranked_orders o
        WHERE o.price_rank <= 10
    )
    LEFT JOIN supplier s ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey LIMIT 1)
    LEFT JOIN supplier_cte so ON so.s_suppkey = s.s_suppkey
)
SELECT f.p_partkey, f.p_name, f.p_brand, f.total_avail_qty,
       f.avg_supply_cost, f.total_revenue, f.return_count
FROM final_results f
WHERE f.revenue_rank <= 10
ORDER BY f.total_revenue DESC;