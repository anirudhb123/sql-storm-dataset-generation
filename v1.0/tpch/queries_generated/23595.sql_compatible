
WITH RECURSIVE nation_hierarchy AS (
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, 1 AS level
    FROM nation n
    WHERE n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE 'E%')
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
    WHERE nh.level < 3
),

supply_data AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) AS rank
    FROM partsupp ps
    WHERE ps.ps_availqty > 0
),

total_orders AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('O', 'P') AND l.l_returnflag = 'N'
    GROUP BY o.o_custkey
),

customer_analysis AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           (SELECT COUNT(DISTINCT o.o_orderkey)
            FROM orders o
            WHERE o.o_custkey = c.c_custkey) AS order_count,
           (SELECT SUM(l.l_extendedprice)
            FROM lineitem l
            JOIN orders o ON l.l_orderkey = o.o_orderkey
            WHERE o.o_custkey = c.c_custkey) AS total_lineitem_amount,
           (SELECT SUM(l.l_extendedprice * (1 - l.l_discount))
            FROM lineitem l
            JOIN orders o ON l.l_orderkey = o.o_orderkey
            WHERE o.o_custkey = c.c_custkey) AS total_spent
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL OR c.c_mktsegment IN ('T1', 'T2')
),

final_summary AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           AVG(sd.ps_supplycost) AS avg_supply_cost
    FROM nation_hierarchy n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN supply_data sd ON sd.ps_suppkey = s.s_suppkey
    GROUP BY n.n_name
)

SELECT ca.c_name, ca.order_count, ca.total_lineitem_amount, fs.supplier_count,
       CASE 
           WHEN fs.avg_supply_cost IS NULL THEN 'No Supply Info'
           ELSE CONCAT('Avg Cost: $', ROUND(fs.avg_supply_cost, 2))
       END AS avg_cost_info,
       (CASE 
           WHEN ca.total_spent > 1000 THEN 'High Value'
           WHEN ca.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
           ELSE 'Low Value'
       END) AS customer_value_category
FROM customer_analysis ca
JOIN final_summary fs ON ca.c_custkey = fs.supplier_count
WHERE fs.supplier_count IS NOT NULL
ORDER BY ca.total_lineitem_amount DESC, fs.supplier_count ASC
LIMIT 10 OFFSET 5;
