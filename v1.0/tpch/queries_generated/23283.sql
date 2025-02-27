WITH RECURSIVE nation_hierarchy AS (
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, 
           CONCAT(n.n_name, ' (Level 0)') AS nation_level
    FROM nation n
    WHERE n.n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, 
           CONCAT(nh.nation_level, ' > ', n.n_name) AS nation_level
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
aggregate_suppliers AS (
    SELECT s.s_nationkey, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(s.s_acctbal) AS total_acctbal,
           Array_Agg(s.s_comment) AS comments_list
    FROM supplier s
    GROUP BY s.s_nationkey
),
ranked_orders AS (
    SELECT o.*, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= '2022-01-01'
),
filtered_lineitems AS (
    SELECT l.*, 
           CASE 
               WHEN l.l_discount > 0.1 THEN 'Discounted'
               ELSE 'Regular Price'
           END AS price_category
    FROM lineitem l
    WHERE l.l_shipdate > l.l_commitdate
),
supplier_part_info AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, p.p_name, p.p_brand, 
           (ps.ps_availqty * p.p_retailprice) AS available_value,
           CASE 
               WHEN ps.ps_supplycost IS NULL THEN 0 
               ELSE ps.ps_supplycost 
           END AS effective_supplycost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
final_selection AS (
    SELECT nh.nation_level, a.supplier_count, a.total_acctbal, 
           SUM(CASE WHEN li.l_returnflag = 'R' THEN li.l_quantity ELSE 0 END) AS total_returns,
           AVG(CASE WHEN li.l_returnflag = 'R' THEN li.l_extendedprice END) AS avg_returned_price,
           STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', p.p_brand, ')')) AS part_info
    FROM nation_hierarchy nh
    LEFT JOIN aggregate_suppliers a ON nh.n_nationkey = a.s_nationkey
    LEFT JOIN filtered_lineitems li ON li.l_orderkey IN (SELECT o.o_orderkey FROM ranked_orders o WHERE o.order_rank <= 10)
    LEFT JOIN supplier_part_info sp ON sp.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = nh.n_nationkey)
    GROUP BY nh.nation_level
)
SELECT * 
FROM final_selection
WHERE (total_returns >= 0 OR part_info IS NOT NULL)
ORDER BY total_acctbal DESC, nation_level;
