WITH supplier_summary AS (
    SELECT s_suppkey, s_name, SUM(ps_supplycost * ps_availqty) AS total_supply_cost
    FROM supplier
    JOIN partsupp ON supplier.s_suppkey = partsupp.ps_suppkey
    GROUP BY s_suppkey, s_name
),
customer_orders AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_custkey
),
nation_region AS (
    SELECT n.n_nationkey, r.r_regionkey
    FROM nation n
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
),
customer_ranked AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
)
SELECT 
    cs.cust_key,
    cs.cust_name,
    COALESCE(cs.total_order_value, 0) AS total_order_value,
    ss.total_supply_cost,
    CASE
        WHEN cs.total_order_value > ss.total_supply_cost THEN 'Profitable'
        ELSE 'Not Profitable'
    END AS profitability_status,
    nr.n_nationkey,
    (SELECT COUNT(*) FROM customer_ranked cr WHERE cr.rank <= 15 AND cr.c_custkey = cs.cust_key) AS top_customers
FROM 
    (SELECT c.c_custkey AS cust_key, c.c_name AS cust_name, co.total_order_value
     FROM customer_ranked c
     LEFT JOIN customer_orders co ON c.c_custkey = co.o_custkey) cs
LEFT JOIN supplier_summary ss ON ss.s_suppkey = (SELECT ps.ps_suppkey 
                                                  FROM partsupp ps
                                                  JOIN lineitem l ON ps.ps_partkey = l.l_partkey
                                                  WHERE l.l_orderkey IN (SELECT o.o_orderkey
                                                                         FROM orders o 
                                                                         WHERE o.o_custkey = cs.cust_key) 
                                                  LIMIT 1)
CROSS JOIN nation_region nr
WHERE 
    cs.total_order_value IS NOT NULL 
    AND ss.total_supply_cost < (SELECT AVG(total_supply_cost) FROM supplier_summary)
ORDER BY 
    profitability_status DESC, cs.total_order_value DESC;
