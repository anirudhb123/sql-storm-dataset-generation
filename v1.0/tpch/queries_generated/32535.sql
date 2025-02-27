WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_nationkey = nh.n_regionkey
),
supplier_info AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_name LIKE 'A%'
),
part_summary AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available_qty, 
           AVG(p.p_retailprice) AS avg_price
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
customer_order_summary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders, 
           SUM(o.o_totalprice) AS total_spent, 
           RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS spending_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    nh.n_name AS nation_name,
    si.s_name AS supplier_name,
    ps.total_available_qty,
    ps.avg_price,
    cos.total_orders,
    cos.total_spent,
    CASE 
        WHEN cos.spending_rank <= 10 THEN 'Top 10 Customers'
        ELSE 'Regular Customers'
    END AS customer_rank
FROM nation_hierarchy nh
FULL OUTER JOIN supplier_info si ON nh.n_nationkey = si.s_nationkey
FULL OUTER JOIN part_summary ps ON si.s_suppkey = ps.p_partkey
LEFT JOIN customer_order_summary cos ON si.s_suppkey = cos.c_custkey
WHERE (si.s_acctbal IS NOT NULL AND si.s_acctbal > 1000) 
   OR (cos.total_orders IS NOT NULL AND cos.total_orders > 5)
ORDER BY nh.level, supplier_name, avg_price DESC;
