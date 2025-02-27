WITH supplier_info AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           CONCAT(UPPER(s.s_name), ' - ', s.s_phone) AS formatted_name_phone,
           (SELECT COUNT(DISTINCT ps.ps_partkey) 
            FROM partsupp ps 
            WHERE ps.ps_suppkey = s.s_suppkey) AS part_count
    FROM supplier s
),
nation_info AS (
    SELECT n.n_nationkey, n.n_name, 
           REPLACE(n.n_comment, 'N/A', '') AS clean_comment
    FROM nation n
),
aggregated_data AS (
    SELECT si.formatted_name_phone, ni.n_name, si.part_count,
           SUM(o.o_totalprice) AS total_orders,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM supplier_info si
    JOIN nation_info ni ON si.s_nationkey = ni.n_nationkey
    JOIN orders o ON o.o_custkey = (SELECT c.c_custkey 
                                      FROM customer c 
                                      WHERE c.c_nationkey = ni.n_nationkey 
                                      LIMIT 1)
    GROUP BY si.formatted_name_phone, ni.n_name, si.part_count
)
SELECT a.formatted_name_phone, a.n_name, a.part_count, 
       CASE WHEN a.total_orders > 1000 THEN 'High' 
            WHEN a.total_orders BETWEEN 500 AND 1000 THEN 'Medium' 
            ELSE 'Low' END AS order_volume_category
FROM aggregated_data a
ORDER BY a.part_count DESC, a.total_orders DESC;
