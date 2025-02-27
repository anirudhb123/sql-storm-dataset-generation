WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS depth
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.depth + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
ranked_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
),
supplier_summary AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
supported_customers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' 
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    nh.n_name AS nation_name,
    ss.s_name AS supplier_name,
    rs.o_orderdate,
    rs.o_totalprice,
    COALESCE(cs.total_spent, 0) AS customer_total_spent,
    CASE 
        WHEN rs.price_rank <= 10 THEN 'Top 10 Orders'
        ELSE 'Other Orders'
    END AS order_category
FROM nation_hierarchy nh
JOIN supplier_summary ss ON nh.n_nationkey = ss.s_suppkey
LEFT JOIN ranked_orders rs ON ss.s_suppkey = rs.o_orderkey
LEFT JOIN supported_customers cs ON rs.o_orderkey = cs.c_custkey
WHERE ss.total_supply_cost > (
    SELECT AVG(ps_total) FROM (
        SELECT SUM(ps_supplycost * ps_availqty) AS ps_total
        FROM partsupp
        GROUP BY ps_suppkey
    ) AS avg_supply_cost
)
ORDER BY nh.n_name, rs.o_orderdate DESC;