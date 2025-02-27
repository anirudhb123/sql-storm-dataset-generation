WITH RECURSIVE Supplier_CTE AS (
    SELECT s_suppkey, s_name, s_address, s_nationkey, s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rn
    FROM supplier
    WHERE s_acctbal IS NOT NULL
),
High_Value_Customers AS (
    SELECT c_custkey, c_name, c_acctbal,
           NTILE(4) OVER (ORDER BY c_acctbal DESC) AS quartile
    FROM customer
    WHERE c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
),
Relevant_Parts AS (
    SELECT p_partkey, p_name, p_brand, p_retailprice,
           CASE 
               WHEN p_size >= 1 AND p_size <= 25 THEN 'Small'
               WHEN p_size > 25 AND p_size <= 50 THEN 'Medium'
               ELSE 'Large' 
           END AS size_category
    FROM part
    WHERE p_retailprice IS NOT NULL
),
Order_Stats AS (
    SELECT o_custkey, COUNT(o_orderkey) AS total_orders,
           SUM(o_totalprice) AS total_spent
    FROM orders
    WHERE o_orderstatus IN ('O', 'F') 
    GROUP BY o_custkey
),
Supplier_Subquery AS (
    SELECT ps_partkey, SUM(ps_supplycost) AS total_supplycost
    FROM partsupp
    GROUP BY ps_partkey
)
SELECT r.r_name, n.n_name, s_cte.s_name, r_parts.p_name,
       COUNT(DISTINCT c.c_custkey) AS high_value_customers,
       SUM(o_stats.total_spent) AS total_spent_by_customers,
       AVG(NULLIF(o_stats.total_orders, 0)) AS avg_orders_per_customer,
       COALESCE(MAX(s_cte.s_acctbal), 0) AS highest_supplier_balance
FROM region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN Supplier_CTE s_cte ON s_cte.rn = 1 AND s_cte.s_nationkey = n.n_nationkey
LEFT JOIN Relevant_Parts r_parts ON r_parts.p_partkey IN (
    SELECT ps_partkey FROM partsupp ps 
    WHERE ps.ps_suppkey = s_cte.s_suppkey
)
LEFT JOIN High_Value_Customers hvc ON hvc.c_custkey = o_stats.o_custkey
JOIN Order_Stats o_stats ON o_stats.o_custkey = hvc.c_custkey
GROUP BY r.r_name, n.n_name, s_cte.s_name, r_parts.p_name
HAVING COUNT(DISTINCT c.c_custkey) > 0 AND MAX(s_cte.s_acctbal) > 1000 
ORDER BY r.r_name, n.n_name, total_spent_by_customers DESC
FETCH FIRST 10 ROWS ONLY;
