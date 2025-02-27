WITH supplier_avg AS (
    SELECT s_nationkey, AVG(s_acctbal) AS avg_acctbal
    FROM supplier
    GROUP BY s_nationkey
), 
part_summary AS (
    SELECT p_partkey, p_name, p_mfgr, p_brand, p_type, 
           SUM(ps_availqty) AS total_avail_qty, 
           SUM(ps_supplycost * ps_availqty) AS total_cost
    FROM part
    JOIN partsupp ON part.p_partkey = partsupp.ps_partkey
    GROUP BY p_partkey, p_name, p_mfgr, p_brand, p_type
), 
customer_orders AS (
    SELECT o.o_orderkey, c.c_custkey, c.c_name, o.o_totalprice, o.o_orderdate
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O'
), 
order_lineitems AS (
    SELECT lo.l_orderkey, SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS revenue
    FROM lineitem lo
    WHERE lo.l_shipdate >= DATE '2023-01-01'
    GROUP BY lo.l_orderkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(CASE WHEN ps.total_avail_qty IS NOT NULL THEN ps.total_avail_qty ELSE 0 END) AS available_quantity,
    ROUND(AVG(ps.total_cost), 2) AS avg_cost,
    COUNT(DISTINCT co.o_orderkey) AS total_orders,
    SUM(ol.revenue) AS total_revenue
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN supplier_avg sa ON s.s_nationkey = sa.s_nationkey
LEFT JOIN part_summary ps ON ps.p_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_suppkey = s.s_suppkey)
LEFT JOIN customer_orders co ON co.o_orderkey IN (SELECT l_orderkey FROM lineitem WHERE l_suppkey = s.s_suppkey)
LEFT JOIN order_lineitems ol ON ol.l_orderkey = co.o_orderkey
WHERE sa.avg_acctbal > 
      (SELECT AVG(avg_acctbal) FROM supplier_avg) -- Correlated subquery for filtering
GROUP BY r.r_name
ORDER BY total_revenue DESC;
