WITH RECURSIVE customer_tree AS (
    SELECT c_custkey, c_name, c_acctbal, 1 AS level
    FROM customer
    WHERE c_acctbal IS NOT NULL AND c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, c.c_acctbal, ct.level + 1
    FROM customer_tree ct
    JOIN customer c ON c.c_custkey = ct.c_custkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer) 
    AND ct.level < 5
),
high_value_orders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice,
           DENSE_RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus = 'F' AND o.o_orderdate >= '2023-01-01'
),
parts_supplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty,
           COALESCE(NULLIF(ps.ps_supplycost, 0), 1) AS safe_supplycost
    FROM partsupp ps
    WHERE ps.ps_availqty > 0
    UNION ALL
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty,
           COALESCE(NULLIF(ps.ps_supplycost, 0), 1) AS safe_supplycost
    FROM partsupp ps
    WHERE ps.ps_availqty IS NULL
),
supply_data AS (
    SELECT p.p_name, SUM(ps.safe_supplycost * ps.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN parts_supplier ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_name
),
final_results AS (
    SELECT ct.c_name, ct.level, SUM(ho.o_totalprice) AS total_order_value,
           AVG(sd.total_supply_cost) AS avg_supply_cost
    FROM customer_tree ct
    LEFT JOIN high_value_orders ho ON ct.c_custkey = ho.o_custkey
    LEFT JOIN supply_data sd ON sd.p_name LIKE '%' || ct.c_name || '%'
    GROUP BY ct.c_name, ct.level
)
SELECT fr.c_name, fr.level,
       CASE 
           WHEN fr.total_order_value IS NULL THEN 'No Orders'
           WHEN fr.avg_supply_cost IS NULL THEN 'Unknown Supply Cost'
           ELSE CONCAT('Total Order Value: ', fr.total_order_value, 
                       ', Avg Supply Cost: ', fr.avg_supply_cost)
       END AS summary
FROM final_results fr
ORDER BY fr.level, fr.c_name;
