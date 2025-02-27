WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS depth
    FROM nation
    WHERE n_regionkey IS NOT NULL
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.depth + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
total_order_value AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
supplier_summary AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
ranked_customers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           DENSE_RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS spending_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT nh.n_name, COUNT(DISTINCT r.c_custkey) AS customer_count,
       AVG(ts.total_value) AS average_order_value,
       SUM(COALESCE(ss.total_cost, 0)) AS total_supplier_cost
FROM nation_hierarchy nh
LEFT JOIN ranked_customers r ON nh.n_nationkey = r.c_custkey
LEFT JOIN total_order_value ts ON r.c_custkey = ts.o_orderkey
LEFT JOIN supplier_summary ss ON ss.s_suppkey = (SELECT ps.ps_suppkey 
                                                  FROM partsupp ps 
                                                  WHERE ps.ps_partkey IN (SELECT p.p_partkey 
                                                                          FROM part p 
                                                                          JOIN lineitem l ON p.p_partkey = l.l_partkey 
                                                                          WHERE l.l_shipdate >= DATE '2023-01-01' 
                                                                          AND l.l_shipdate < DATE '2023-12-31'))
WHERE nh.depth = 1
GROUP BY nh.n_name
ORDER BY customer_count DESC, average_order_value DESC;
