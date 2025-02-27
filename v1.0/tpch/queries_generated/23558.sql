WITH RECURSIVE future_orders AS (
    SELECT o_orderkey, 
           o_custkey, 
           o_orderdate, 
           o_totalprice, 
           o_orderstatus, 
           ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_orderdate DESC) AS rn
    FROM orders
    WHERE o_orderdate > CURRENT_DATE
), 
high_value_customers AS (
    SELECT c_custkey, 
           SUM(o_totalprice) as total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.custkey
    HAVING SUM(o_totalprice) > 10000
), 
filtered_parts AS (
    SELECT p_pkey,
           p_name,
           COUNT(ps_suppkey) AS supplier_count,
           MAX(ps_supplycost) AS max_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p_pkey
    HAVING SUM(ps_availqty) IS NULL OR COUNT(ps_suppkey) > 5
)
SELECT 
    c.c_name, 
    COALESCE(fo.o_orderkey, 0) AS future_order, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    RANK() OVER (PARTITION BY c.c_custkey ORDER BY COALESCE(fo.o_orderdate, '1900-01-01') DESC) as order_priority,
    CASE WHEN hp.total_spent IS NOT NULL THEN 'High Value' ELSE 'Regular' END AS customer_segment
FROM customer c
LEFT JOIN future_orders fo ON c.c_custkey = fo.o_custkey
LEFT JOIN lineitem l ON fo.o_orderkey = l.l_orderkey
LEFT JOIN high_value_customers hp ON c.c_custkey = hp.c_custkey
JOIN filtered_parts fp ON l.l_partkey = fp.p_partkey
WHERE l.l_shipmode IN ('TRUCK', 'SHIP') 
  AND (l.l_returnflag IS NULL OR l.l_returnflag = 'N')
GROUP BY c.c_name, fo.o_orderkey, hp.total_spent
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 
       (SELECT AVG(l2.l_extendedprice) 
        FROM lineitem l2 
        WHERE l2.l_discount BETWEEN 0.05 AND 0.15 
          AND l2.l_shipdate <= CURRENT_DATE)
ORDER BY revenue DESC, customer_segment, order_priority;
