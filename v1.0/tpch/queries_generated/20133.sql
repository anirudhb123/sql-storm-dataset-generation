WITH RECURSIVE ranked_orders AS (
    SELECT o_orderkey, o_orderdate, o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o_orderstatus ORDER BY o_totalprice DESC) AS rank_status
    FROM orders
), customer_summary AS (
    SELECT c_custkey, c_name, c_acctbal, c_mktsegment,
           (SELECT COUNT(*) FROM orders o WHERE o.o_custkey = c.custkey) AS order_count,
           NULLIF(MAX(o.o_totalprice), 0) AS max_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal, c.c_mktsegment
), part_availability AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail
    FROM partsupp ps
    WHERE ps.ps_supplycost > (SELECT AVG(ps_supplycost) FROM partsupp)
    GROUP BY ps.ps_partkey
)

SELECT c.c_name, c.c_acctbal,
       COALESCE(o.rank_status, 'No Orders') AS order_rank,
       p.p_name,
       pa.total_avail,
       CASE 
           WHEN c.c_acctbal IS NULL THEN 'Account No Balance' 
           WHEN c.c_acctbal < 1000 THEN 'Low Balance' 
           ELSE 'Sufficient Balance' 
       END AS balance_status
FROM customer_summary c
LEFT JOIN ranked_orders o ON c.c_custkey = o.o_orderkey
LEFT JOIN lineitem l ON l.l_orderkey IN (SELECT o_orderkey FROM orders WHERE o_custkey = c.c_custkey)
LEFT JOIN part_availability pa ON pa.ps_partkey = l.l_partkey
LEFT JOIN part p ON p.p_partkey = l.l_partkey
WHERE (c.c_mktsegment = 'BUILDING' OR c.c_mktsegment IS NULL)
  AND (o.order_rank IS NOT NULL OR c.c_acctbal IS NULL)
  AND pa.total_avail > 0
ORDER BY c.c_name, o.rank_status DESC NULLS LAST;
