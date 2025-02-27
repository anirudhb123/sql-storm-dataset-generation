
WITH region_summary AS (
    SELECT r.r_regionkey, 
           r.r_name, 
           COUNT(DISTINCT n.n_nationkey) AS nation_count,
           SUM(s.s_acctbal) AS total_acctbal,
           COUNT(DISTINCT c.c_custkey) FILTER (WHERE c.c_acctbal > 0) AS positive_customers
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN customer c ON s.s_nationkey = c.c_nationkey
    GROUP BY r.r_regionkey, r.r_name
),
order_summary AS (
    SELECT o.o_orderkey, 
           o.o_custkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS row_num
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
),
detailed_orders AS (
    SELECT o.o_orderkey,
           o.o_orderstatus,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           COUNT(l.l_linenumber) AS line_count,
           MAX(o.o_orderdate) AS latest_order_date,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS cust_order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1997-01-01' OR l.l_returnflag IS NULL
    GROUP BY o.o_orderkey, o.o_orderstatus, o.o_custkey
),
final_summary AS (
    SELECT r.r_regionkey,
           r.r_name,
           rs.nation_count,
           rs.total_acctbal,
           ds.o_orderkey,
           ds.total_price,
           ds.latest_order_date,
           ds.cust_order_rank
    FROM region_summary rs
    JOIN region r ON rs.r_regionkey = r.r_regionkey
    LEFT JOIN detailed_orders ds ON rs.nation_count = ds.cust_order_rank
)
SELECT f.r_name,
       COALESCE(SUM(f.total_price), 0) AS aggregate_total_price,
       COUNT(DISTINCT f.o_orderkey) AS unique_orders,
       STRING_AGG(DISTINCT CONCAT('Order ', CAST(f.o_orderkey AS TEXT), ' - ', CAST(f.latest_order_date AS TEXT)), ', ') AS order_details
FROM final_summary f
GROUP BY f.r_name
HAVING SUM(f.total_price) > (
    SELECT AVG(total_price) FROM detailed_orders WHERE total_price IS NOT NULL
)
ORDER BY aggregate_total_price DESC NULLS LAST;
