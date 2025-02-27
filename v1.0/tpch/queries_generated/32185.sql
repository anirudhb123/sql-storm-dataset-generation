WITH RECURSIVE sales_summary AS (
    SELECT c.c_custkey,
           c.c_name,
           SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count,
           RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank_within_nation
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
),
supplier_summary AS (
    SELECT s.s_suppkey, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_inventory_value
    FROM supplier s
    INNER JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
popular_parts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT ss.c_name,
       ss.total_spent,
       ss.order_count,
       ss.rank_within_nation,
       ps.p_name,
       ps.total_sales,
       COALESCE(ps.total_sales / NULLIF(ss.total_spent, 0), 0) AS sales_to_spending_ratio,
       CASE 
           WHEN ss.total_spent > 2000 THEN 'High Value'
           WHEN ss.total_spent BETWEEN 1000 AND 2000 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS customer_value_category,
       s.s_name,
       s.total_inventory_value
FROM sales_summary ss
LEFT JOIN popular_parts ps ON ss.rank_within_nation <= 10
JOIN supplier_summary s ON s.total_inventory_value > (SELECT AVG(total_inventory_value) FROM supplier_summary)
WHERE ss.total_spent IS NOT NULL
ORDER BY ss.total_spent DESC, ps.total_sales DESC;
