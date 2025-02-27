WITH RECURSIVE ranked_orders AS (
    SELECT o_orderkey, o_totalprice, o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY o_orderstatus ORDER BY o_totalprice DESC) AS order_rank
    FROM orders
    WHERE o_orderdate BETWEEN '2022-01-01' AND '2023-01-01'
), supplier_part_info AS (
    SELECT ps_partkey, ps_suppkey, ps_availqty, ps_supplycost,
           (CASE WHEN ps_availqty IS NULL THEN 0 ELSE ps_availqty END) / NULLIF(ps_supplycost, 0) AS adjusted_avail
    FROM partsupp
    WHERE ps_supplycost > 0
), customer_summary AS (
    SELECT c_nationkey, COUNT(DISTINCT c_custkey) AS total_customers,
           SUM(c_acctbal) AS total_acctbal,
           STRING_AGG(c_name, ', ') AS customer_names
    FROM customer
    GROUP BY c_nationkey
), part_supplier AS (
    SELECT p.p_partkey, p.p_name, s.s_suppkey, s.s_name,
           (p.p_retailprice * 1.05) AS retailprice_with_markup,
           COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_extended_price
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name, s.s_suppkey, s.s_name
    HAVING SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) = 0
), total_supplier_data AS (
    SELECT s.s_nationkey, SUM(ps.ps_availqty) AS total_avail_qty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_nationkey
)
SELECT r.r_name, SUM(c.total_acctbal) AS total_account_balance,
       AVG(p.retailprice_with_markup) AS avg_retail_price,
       COUNT(DISTINCT o.o_orderkey) AS total_orders,
       COUNT(DISTINCT pi.s_name) AS unique_suppliers,
       STRING_AGG(DISTINCT CONCAT('Order ', o.order_rank, ': ', o.o_orderkey), '; ') AS order_details
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN customer_summary c ON n.n_nationkey = c.c_nationkey
LEFT JOIN ranked_orders o ON o.o_orderkey IN (SELECT DISTINCT o_orderkey FROM orders)
LEFT JOIN part_supplier p ON p.p_partkey IN (SELECT ps_partkey FROM supplier_part_info)
LEFT JOIN total_supplier_data sd ON n.n_nationkey = sd.s_nationkey
GROUP BY r.r_name
HAVING COUNT(DISTINCT c.c_nationkey) > 1
ORDER BY total_account_balance DESC
LIMIT 10
OFFSET CASE WHEN (SELECT COUNT(*) FROM lineitem) % 2 = 0 THEN 0 ELSE 5 END;
