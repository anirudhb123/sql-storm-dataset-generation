WITH RECURSIVE top_suppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_cost DESC
    LIMIT 10
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, COALESCE(SUM(o.o_totalprice), 0) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 5
),
high_value_orders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice
    FROM orders o
    WHERE o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders) 
),
region_nations AS (
    SELECT r.r_name, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM region r
    JOIN nation n ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name, n.n_name
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    ts.s_name AS top_supplier,
    c.c_name AS customer_name,
    co.order_count,
    co.total_spent,
    hv.o_orderkey,
    hv.o_totalprice,
    ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY co.total_spent DESC) AS customer_rank
FROM region_nations r_n
JOIN region r ON r.r_name = r_n.r_name
JOIN nation n ON n.n_name = r_n.n_name
JOIN top_suppliers ts ON ts.s_suppkey IN (
    SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (
        SELECT p.p_partkey FROM part p WHERE p.p_size > 10
    )
)
LEFT JOIN customer_orders co ON co.c_custkey IN (
    SELECT o.o_custkey FROM high_value_orders hv 
    JOIN lineitem l ON l.l_orderkey = hv.o_orderkey 
    WHERE l.l_discount > 0.05
)
LEFT JOIN high_value_orders hv ON hv.o_orderkey = co.o_orderkey
WHERE co.total_spent IS NOT NULL
ORDER BY r.r_name, n.n_name, co.total_spent DESC;
