
WITH supplier_details AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           REPLACE(s.s_comment, 'excellent', 'superior') AS updated_comment,
           CONCAT('Supplier: ', s.s_name, ', Balance: ', CAST(s.s_acctbal AS VARCHAR(20))) AS summary
    FROM supplier s
),
part_details AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr,
           TRIM(SUBSTRING(p.p_comment, 1, 10)) AS short_comment,
           UPPER(p.p_type) AS uppercase_type,
           p.p_retailprice
    FROM part p
    WHERE p.p_retailprice > 50.00
),
order_info AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderstatus,
           COUNT(l.l_orderkey) AS item_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1998-10-01' - INTERVAL '90 days'
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderstatus
),
final_benchmark AS (
    SELECT pd.p_name, pd.uppercase_type, sd.summary,
           oi.total_revenue, oi.item_count, sd.updated_comment
    FROM part_details pd
    JOIN supplier_details sd ON MOD(pd.p_partkey, 10) = MOD(sd.s_suppkey, 10)
    JOIN order_info oi ON MOD(oi.o_custkey, 100) = sd.s_nationkey
    WHERE oi.item_count > 5
    ORDER BY oi.total_revenue DESC
)
SELECT *
FROM final_benchmark
LIMIT 100;
