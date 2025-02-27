WITH RECURSIVE order_recursive AS (
    SELECT o_orderkey, o_custkey, o_orderstatus, o_totalprice, o_orderdate, 
           o_orderpriority, ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_orderdate) AS order_rank
    FROM orders
    WHERE o_orderdate >= '1997-01-01'
),
supplier_summary AS (
    SELECT s_nationkey, SUM(ps_availqty) AS total_available,
           AVG(ps_supplycost) AS avg_supplycost
    FROM partsupp
    JOIN supplier ON ps_suppkey = s_suppkey
    GROUP BY s_nationkey
),
lineitem_status AS (
    SELECT l_suppkey, SUM(l_extendedprice * (1 - l_discount)) AS total_sales,
           COUNT(l_orderkey) AS total_orders,
           ROW_NUMBER() OVER (PARTITION BY l_suppkey ORDER BY SUM(l_extendedprice * (1 - l_discount)) DESC) AS sales_rank
    FROM lineitem
    GROUP BY l_suppkey
)
SELECT r.r_name, n.n_name, s.s_name,
       COALESCE(ss.total_available, 0) AS total_available,
       COALESCE(ls.total_sales, 0) AS total_sales,
       COUNT(DISTINCT orc.o_orderkey) AS number_of_orders,
       SUM(orc.o_totalprice) AS total_revenue
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN supplier_summary ss ON s.s_nationkey = ss.s_nationkey
LEFT JOIN lineitem_status ls ON s.s_suppkey = ls.l_suppkey
LEFT JOIN order_recursive orc ON orc.o_custkey = (SELECT c.c_custkey 
                                                    FROM customer c 
                                                    WHERE c.c_nationkey = n.n_nationkey 
                                                    LIMIT 1)
WHERE (CASE 
           WHEN ss.total_available IS NULL THEN FALSE
           ELSE ss.total_available > 1000 AND ls.total_sales > 5000 
       END)
GROUP BY r.r_name, n.n_name, s.s_name, ss.total_available, ls.total_sales
HAVING COUNT(DISTINCT orc.o_orderkey) > 5
ORDER BY total_revenue DESC;