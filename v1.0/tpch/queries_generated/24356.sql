WITH RECURSIVE nation_ranks AS (
    SELECT n_nationkey, n_name, n_regionkey, n_comment,
           ROW_NUMBER() OVER (PARTITION BY n_regionkey ORDER BY n_nationkey) AS rank
    FROM nation
),
supplier_summary AS (
    SELECT s_nationkey, COUNT(s_suppkey) AS total_suppliers, 
           SUM(s_acctbal) AS total_acct_balance,
           AVG(CASE WHEN s_acctbal IS NOT NULL THEN s_acctbal ELSE 0 END) AS avg_account_balance
    FROM supplier
    GROUP BY s_nationkey
),
part_availability AS (
    SELECT ps_partkey, SUM(ps_availqty) AS total_available
    FROM partsupp
    GROUP BY ps_partkey
),
order_details AS (
    SELECT o_orderkey, o_custkey, o_totalprice, 
           SUM(l_extendedprice * (1 - l_discount)) AS order_value,
           COUNT(l_orderkey) AS items_count
    FROM orders
    JOIN lineitem ON o_orderkey = l_orderkey
    GROUP BY o_orderkey, o_custkey, o_totalprice
),
high_value_orders AS (
    SELECT o_custkey, o_orderkey, order_value
    FROM order_details
    WHERE order_value > (SELECT AVG(order_value) FROM order_details)
)
SELECT n.n_name, 
       COALESCE(s.total_suppliers, 0) AS total_suppliers, 
       COALESCE(s.total_acct_balance, 0) AS total_balance,
       p.p_name, 
       COALESCE(pa.total_available, 0) AS available_qty,
       COUNT(DISTINCT hvo.o_orderkey) AS high_value_order_count,
       ARRAY_AGG(DISTINCT hvo.o_orderkey) FILTER (WHERE hvo.o_orderkey IS NOT NULL) AS high_value_order_ids
FROM nation_ranks n
LEFT JOIN supplier_summary s ON n.n_nationkey = s.s_nationkey
LEFT JOIN part_availability pa ON pa.ps_partkey = (SELECT ps_partkey FROM partsupp WHERE ps_supplycost = (SELECT MIN(ps_supplycost) FROM partsupp))
LEFT JOIN part p ON p.p_partkey = pa.ps_partkey
LEFT JOIN high_value_orders hvo ON hvo.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey LIMIT 1)
WHERE n.r_regionkey IN (SELECT DISTINCT n_regionkey FROM nation WHERE n_name LIKE 'A%')
GROUP BY n.n_name, s.total_suppliers, s.total_acct_balance, p.p_name, pa.total_available
HAVING SUM(pa.total_available) > 1000 AND COUNT(DISTINCT hvo.o_orderkey) > 5
ORDER BY n.n_name, available_qty DESC NULLS LAST;
