WITH RECURSIVE region_nation AS (
    SELECT r_regionkey, r_name, r_comment,
           ROW_NUMBER() OVER (PARTITION BY r_regionkey ORDER BY n_nationkey) as rn
    FROM region
    LEFT JOIN nation ON region.r_regionkey = nation.n_regionkey
),

current_customer AS (
    SELECT c_custkey, c_name, c_acctbal,
           CASE WHEN c_acctbal IS NULL THEN 'Unknown' ELSE c_name END AS cust_info
    FROM customer
    WHERE c_acctbal > 500 OR c_name LIKE '%Special%'
),

filtered_parts AS (
    SELECT p_partkey, p_name, p_retailprice,
           CASE WHEN p_retailprice < 5 THEN NULL ELSE p_retailprice * 0.9 END AS discounted_price,
           LENGTH(p_comment) AS comment_length
    FROM part
    WHERE p_size IN (SELECT DISTINCT CASE WHEN ps_availqty IS NULL THEN 0 ELSE ps_availqty END FROM partsupp)
),

order_summary AS (
    SELECT o_orderkey, o_custkey,
           SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
           COUNT(l_orderkey) AS item_count,
           RANK() OVER (ORDER BY SUM(l_extendedprice * (1 - l_discount)) DESC) AS revenue_rank
    FROM orders
    JOIN lineitem ON orders.o_orderkey = lineitem.l_orderkey
    GROUP BY o_orderkey, o_custkey
)

SELECT rn, r_name, total_revenue, item_count, cust_info,
       COALESCE(NULLIF(discounted_price, 0), 'Not Applicable') AS final_price_statement
FROM region_nation
FULL OUTER JOIN order_summary ON region_nation.r_regionkey = order_summary.o_custkey % 10
LEFT JOIN current_customer ON order_summary.o_custkey = current_customer.c_custkey
WHERE total_revenue > 1000 OR final_price_statement IS NOT NULL
ORDER BY total_revenue DESC NULLS LAST
FETCH FIRST 50 ROWS ONLY;
