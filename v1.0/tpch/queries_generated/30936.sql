WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS hierarchy_level
    FROM nation
    WHERE n_nationkey = 1
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.hierarchy_level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_regionkey
),
total_supply AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
avg_price AS (
    SELECT l.l_partkey, AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_discounted_price
    FROM lineitem l
    GROUP BY l.l_partkey
),
supplier_orders AS (
    SELECT s.s_suppkey, s.s_name, COUNT(o.o_orderkey) AS order_count
    FROM supplier s
    LEFT JOIN lineitem l ON s.s_suppkey = l.l_suppkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY s.s_suppkey, s.s_name
),
high_value_suppliers AS (
    SELECT so.s_suppkey, so.s_name
    FROM supplier_orders so
    WHERE so.order_count > 50
),
part_details AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, COALESCE(tp.total_avail_qty, 0) AS total_available
    FROM part p
    LEFT JOIN total_supply tp ON p.p_partkey = tp.ps_partkey
),
final_data AS (
    SELECT pd.p_partkey, pd.p_name, pd.p_retailprice, pd.total_available,
           ROW_NUMBER() OVER (PARTITION BY pd.p_partkey ORDER BY pd.p_retailprice DESC) AS price_rank,
           CASE WHEN pd.total_available > 1000 THEN 'High Availability' ELSE 'Low Availability' END AS availability_status
    FROM part_details pd
    WHERE pd.p_retailprice IS NOT NULL AND pd.total_available IS NOT NULL
)
SELECT fd.p_partkey, fd.p_name, fd.p_retailprice, fd.total_available, fd.price_rank, fd.availability_status, nh.n_name AS nation_name
FROM final_data fd
LEFT JOIN nation_hierarchy nh ON nh.n_nationkey = (SELECT s_nationkey FROM supplier WHERE s_suppkey IN (SELECT s_suppkey FROM high_value_suppliers))
WHERE fd.availability_status = 'High Availability'
ORDER BY fd.p_retailprice DESC
LIMIT 10;
