WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name = 'EUROPE')
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_regionkey
    WHERE nh.level < 5
), 
supplier_info AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn,
           COALESCE(NULLIF(REGEXP_REPLACE(s.s_phone, '[^0-9]', ''), ''), 'N/A') AS formatted_phone
    FROM supplier s
    JOIN nation_hierarchy nh ON s.s_nationkey = nh.n_nationkey
), 
order_summary AS (
    SELECT o.o_orderkey, o.o_orderdate, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           AVG(l.l_tax) AS avg_tax_rate, 
           COUNT(DISTINCT l.l_linenumber) AS line_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE EXISTS (
        SELECT 1 
        FROM partsupp ps 
        WHERE ps.ps_partkey = l.l_partkey 
          AND ps.ps_availqty > 0
          AND ps.ps_supplycost < (SELECT AVG(ps2.ps_supplycost) 
                                   FROM partsupp ps2 
                                   WHERE ps2.ps_partkey = l.l_partkey)
    )
    GROUP BY o.o_orderkey, o.o_orderdate
), 
final_report AS (
    SELECT n.n_name AS nation_name, 
           SUM(os.total_sales) AS total_sales_sum, 
           COUNT(DISTINCT os.o_orderkey) AS order_count,
           STRING_AGG(DISTINCT si.formatted_phone, ', ') AS supplier_phones
    FROM order_summary os
    JOIN supplier_info si ON si.rn <= 3
    JOIN nation n ON si.s_nationkey = n.n_nationkey
    GROUP BY n.n_name
)
SELECT fr.nation_name, fr.total_sales_sum, fr.order_count,
       CASE 
           WHEN fr.total_sales_sum IS NULL THEN 'No Sales' 
           ELSE 'Sales Present' 
       END AS sales_status
FROM final_report fr
WHERE fr.total_sales_sum > 100000
ORDER BY fr.total_sales_sum DESC
LIMIT 10;
