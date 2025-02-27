WITH RECURSIVE supply_chain AS (
    SELECT ps.s_partkey, ps.s_suppkey, ps.ps_availqty, ps.ps_supplycost, 
           ROW_NUMBER() OVER (PARTITION BY ps.s_partkey ORDER BY ps.ps_supplycost ASC) as rn
    FROM partsupp ps
    WHERE ps.ps_availqty > 0
), ranked_suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, r.r_name, 
           ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY s.s_acctbal DESC) as regional_rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
), order_details AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_partkey) AS part_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate
), aggregated_sales AS (
    SELECT o.orderdate, 
           SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice ELSE 0 END) AS returned_sales,
           SUM(CASE WHEN l.l_returnflag = 'A' THEN l.l_extendedprice ELSE 0 END) AS available_sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY o.o_orderdate
)
SELECT r.region,
       COUNT(DISTINCT os.o_orderkey) AS total_orders,
       AVG(ads.total_revenue) AS avg_revenue_per_order,
       MAX(ads.part_count) AS max_parts_in_order,
       SUM(rs.s_acctbal) AS total_acctbal,
       SUM(COALESCE(ads.returned_sales, 0)) AS total_returns
FROM ranked_suppliers rs
FULL OUTER JOIN order_details ads ON rs.s_suppkey = ads.o_orderkey
LEFT JOIN aggregated_sales os ON ads.o_orderdate = os.orderdate
JOIN nation n ON rs.n_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE (rs.regional_rank <= 5 OR rs.s_acctbal > 10000)
GROUP BY r.region
HAVING COUNT(DISTINCT os.o_orderkey) > 50
ORDER BY total_orders DESC;
