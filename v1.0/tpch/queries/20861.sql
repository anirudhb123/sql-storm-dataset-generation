WITH RECURSIVE cust_orders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), order_details AS (
    SELECT o.o_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY l.l_orderkey) AS item_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
), supplier_part AS (
    SELECT ps.ps_partkey, s.s_name, ps.ps_availqty, MAX(ps.ps_supplycost) AS max_supplycost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_name, ps.ps_availqty
), ranked_parts AS (
    SELECT *, 
           DENSE_RANK() OVER (PARTITION BY ps_partkey ORDER BY max_supplycost DESC) AS supply_rank
    FROM supplier_part
), expensive_parts AS (
    SELECT p.p_partkey, p.p_name, rp.s_name, rp.max_supplycost
    FROM part p
    JOIN ranked_parts rp ON p.p_partkey = rp.ps_partkey
    WHERE rp.supply_rank = 1 AND rp.max_supplycost >= 100.00
), customer_analysis AS (
    SELECT co.c_custkey, co.c_name, co.total_spent,
           CASE WHEN co.total_spent IS NULL THEN 'No Purchases' 
                WHEN co.total_spent < 500 THEN 'Low Spender' 
                WHEN co.total_spent BETWEEN 500 AND 1000 THEN 'Medium Spender'
                ELSE 'High Spender' END AS spending_category
    FROM cust_orders co
)
SELECT ca.c_custkey, ca.c_name, ca.total_spent, ca.spending_category,
       ep.p_name, ep.max_supplycost, 
       COUNT(od.item_rank) AS item_count, 
       SUM(od.l_extendedprice) AS total_order_value
FROM customer_analysis ca
LEFT JOIN order_details od ON ca.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = od.o_orderkey)
LEFT JOIN expensive_parts ep ON od.l_partkey = ep.p_partkey
GROUP BY ca.c_custkey, ca.c_name, ca.total_spent, ca.spending_category, ep.p_name, ep.max_supplycost
HAVING (SUM(od.l_extendedprice) IS NOT NULL OR COUNT(od.item_rank) > 0)
ORDER BY ca.total_spent DESC, ep.max_supplycost ASC
LIMIT 100 OFFSET (SELECT COUNT(*) FROM customer) / 100;
