WITH RECURSIVE supplier_cte AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rn
    FROM supplier
), 
part_availability AS (
    SELECT ps_partkey,
           SUM(ps_availqty) AS total_avail,
           SUM(ps_supplycost * ps_availqty) AS total_cost
    FROM partsupp
    GROUP BY ps_partkey
), 
order_summary AS (
    SELECT o_custkey, 
           COUNT(o_orderkey) AS order_count,
           SUM(o_totalprice) AS total_spent,
           AVG(o_totalprice) AS avg_order_value
    FROM orders
    GROUP BY o_custkey
),
lineitem_summary AS (
    SELECT l_orderkey,
           SUM(l_extendedprice * (1 - l_discount)) AS total_line_value,
           COUNT(DISTINCT l_partkey) AS distinct_parts
    FROM lineitem
    GROUP BY l_orderkey
)
SELECT p.p_name,
       r.r_name AS region_name,
       o.order_count,
       o.total_spent,
       o.avg_order_value,
       l.distinct_parts,
       COALESCE(NULLIF(l.total_line_value, 0), NULL) AS adjusted_line_value,
       CASE 
           WHEN o.total_spent > 100000 THEN 'High Roller'
           WHEN o.total_spent BETWEEN 50000 AND 100000 THEN 'Mid Tier'
           ELSE 'Low Tier'
       END AS customer_tier
FROM part p
JOIN part_availability pa ON p.p_partkey = pa.ps_partkey
LEFT JOIN lineitem_summary l ON l.l_orderkey IN (SELECT o_orderkey 
                                                  FROM orders 
                                                  WHERE o_custkey = ANY (SELECT c_custkey FROM customer WHERE c_nationkey = p.p_partkey % 10))
JOIN order_summary o ON o.o_custkey = (SELECT c_custkey FROM customer WHERE c_nationkey = p.p_partkey % 10 LIMIT 1)
JOIN nation n ON n.n_nationkey = (SELECT s_nationkey FROM supplier_cte WHERE rn = 1 OFFSET (p.p_partkey % 5))
JOIN region r ON r.r_regionkey = n.n_regionkey
WHERE pa.total_avail > 0
  AND adjusted_line_value IS NULL OR adjusted_line_value > 1000
ORDER BY adjusted_line_value DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;
