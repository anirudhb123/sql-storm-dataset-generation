WITH RECURSIVE nation_supplier AS (
    SELECT n.n_name, s.s_suppkey, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) as rnk
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE s.s_acctbal IS NOT NULL
), 
recent_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= (SELECT DATEADD(year, -2, CURRENT_DATE) FROM dual)
), 
part_supplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty * ps.ps_supplycost) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
), 
line_item_stats AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(*) AS total_items
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
    GROUP BY l.l_orderkey
)

SELECT p.p_name, 
       ns.n_name AS supplier_nation,
       ps.total_cost,
       COALESCE(ri.total_revenue, 0) AS recent_revenue,
       CASE 
            WHEN ri.total_revenue IS NULL THEN 'No Recent Orders'
            WHEN ri.total_revenue > 10000 THEN 'High Revenue'
            ELSE 'Low Revenue'
       END AS revenue_category,
       ROW_NUMBER() OVER (PARTITION BY ns.n_name ORDER BY ps.total_cost DESC) as rank_by_cost
FROM part p
LEFT JOIN part_supplier ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN nation_supplier ns ON ps.ps_suppkey = ns.s_suppkey AND ns.rnk = 1
LEFT JOIN recent_orders ri ON ns.s_suppkey = ri.o_orderkey
WHERE p.p_retailprice IS NOT NULL
AND (ps.total_cost IS NOT NULL OR ns.n_name IS NULL)
ORDER BY 1, 4 DESC NULLS LAST
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
