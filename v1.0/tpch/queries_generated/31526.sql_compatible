
WITH RECURSIVE order_summary AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01'
), supplier_summary AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), lineitem_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_price
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '1997-01-01'
    GROUP BY l.l_orderkey
), nation_region AS (
    SELECT n.n_nationkey, n.n_name, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT n.n_name, r.r_name, ss.s_name, SUM(ls.total_line_price) AS total_revenue, 
       ss.total_cost, 
       CASE WHEN SUM(ls.total_line_price) > ss.total_cost 
            THEN 'Profitable' 
            ELSE 'Not Profitable' 
       END AS profitability_status
FROM lineitem_summary ls
JOIN order_summary os ON ls.l_orderkey = os.o_orderkey
JOIN supplier_summary ss ON ss.s_suppkey = (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    WHERE ps.ps_partkey = (
        SELECT l.l_partkey 
        FROM lineitem l 
        WHERE l.l_orderkey = os.o_orderkey 
        LIMIT 1
    )
    LIMIT 1
)
JOIN nation_region n ON n.n_nationkey = (
    SELECT c.c_nationkey 
    FROM customer c 
    JOIN orders o ON c.c_custkey = o.o_custkey 
    WHERE o.o_orderkey = os.o_orderkey 
    LIMIT 1
)
JOIN region r ON n.r_name = r.r_name
GROUP BY n.n_name, r.r_name, ss.s_name, ss.total_cost
HAVING SUM(ls.total_line_price) > 0
ORDER BY total_revenue DESC
LIMIT 10;
