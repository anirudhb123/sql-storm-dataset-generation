WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name LIKE 'Asia%')
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
SupplierAvailability AS (
    SELECT s.s_suppkey, SUM(ps.ps_availqty) AS total_avail_qty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
OrderSummary AS (
    SELECT o.o_custkey, COUNT(o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS orders_value, AVG(o.o_totalprice) AS avg_order_value
    FROM orders o
    GROUP BY o.o_custkey
),
CustomerRank AS (
    SELECT c.c_custkey, c.c_name, os.total_orders, os.orders_value,
           ROW_NUMBER() OVER (ORDER BY os.orders_value DESC) AS order_rank
    FROM customer c
    JOIN OrderSummary os ON c.c_custkey = os.o_custkey
)
SELECT n.n_name AS nation_name, 
       COUNT(DISTINCT c.c_custkey) AS total_customers,
       SUM(sa.total_avail_qty) AS total_available_parts,
       AVG(cr.avg_order_value) AS avg_order_value,
       MAX(cr.total_orders) AS max_orders_by_customer
FROM nation n
LEFT JOIN CustomerRank cr ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = cr.c_custkey)
LEFT JOIN SupplierAvailability sa ON n.n_nationkey = (SELECT DISTINCT s.s_nationkey FROM supplier s WHERE s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size < 15))))
GROUP BY n.n_name
HAVING SUM(sa.total_avail_qty) IS NOT NULL
ORDER BY total_available_parts DESC;
