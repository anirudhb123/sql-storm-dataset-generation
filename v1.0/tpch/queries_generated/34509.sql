WITH RECURSIVE region_hierarchy AS (
    SELECT r_regionkey, r_name, 1 AS level
    FROM region
    WHERE r_regionkey = 1  -- Assuming regionkey '1' is the top level for hierarchy

    UNION ALL

    SELECT r.r_regionkey, r.r_name, rh.level + 1
    FROM region r
    JOIN region_hierarchy rh ON r.r_regionkey = rh.r_regionkey + 1  -- Recursive join for hierarchy
),

customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'P')  -- Only Open and Pending orders
),

part_supplier_totals AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),

supplier_part_details AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_retailprice,
           CASE 
               WHEN p.p_retailprice < 100 THEN 'Low'
               WHEN p.p_retailprice BETWEEN 100 AND 500 THEN 'Medium'
               ELSE 'High'
           END AS price_category
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
)

SELECT 
    rh.r_name AS region_name,
    co.c_name AS customer_name,
    COUNT(DISTINCT co.o_orderkey) AS total_orders,
    SUM(p.p_retailprice) AS total_retail_value,
    AVG(p.p_retailprice) AS average_retail_value,
    STDEV(p.p_retailprice) AS stddev_retail_value,
    ps.total_supplycost AS total_supply_cost
FROM region_hierarchy rh
LEFT JOIN customer_orders co ON co.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = rh.r_regionkey)
LEFT JOIN supplier_part_details p ON p.s_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = co.c_custkey)
LEFT JOIN part_supplier_totals ps ON ps.ps_partkey = p.p_partkey
GROUP BY rh.r_name, co.c_name, ps.total_supplycost
HAVING COUNT(DISTINCT co.o_orderkey) > 5
ORDER BY region_name, total_orders DESC;
