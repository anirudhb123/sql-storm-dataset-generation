WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'Africa')
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
), avg_supply_cost AS (
    SELECT ps_partkey, AVG(ps_supplycost) AS avg_cost
    FROM partsupp
    GROUP BY ps_partkey
), high_value_customers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
), order_summary AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, o.cust_info
    FROM orders o
    LEFT JOIN (
        SELECT o_orderkey, STRING_AGG(DISTINCT c.c_name, ', ') AS cust_info
        FROM lineitem l
        JOIN orders o ON l.l_orderkey = o.o_orderkey
        JOIN customer c ON o.o_custkey = c.c_custkey
        GROUP BY o_orderkey
    ) as customer_details ON o.o_orderkey = customer_details.o_orderkey
), ranked_orders AS (
    SELECT os.*, RANK() OVER (PARTITION BY os.o_orderdate ORDER BY os.o_totalprice DESC) AS order_rank
    FROM order_summary os
)
SELECT n_h.n_name AS nation_name, 
       r.r_name AS region_name, 
       hvc.c_name AS high_value_customer,
       ro.o_totalprice,
       ro.o_orderdate,
       COALESCE(ro.cust_info, 'No customers') AS customer_details
FROM nation_hierarchy n_h
JOIN region r ON n_h.n_regionkey = r.r_regionkey
LEFT JOIN high_value_customers hvc ON hvc.c_nationkey = n_h.n_nationkey
LEFT JOIN ranked_orders ro ON ro.o_orderkey IN (
    SELECT l_orderkey FROM lineitem WHERE l_partkey IN (
        SELECT p_partkey FROM part WHERE p_retailprice > 100.00
    )
)
WHERE ro.order_rank <= 10
ORDER BY nation_name, region_name, high_value_customer;
