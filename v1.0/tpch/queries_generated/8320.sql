WITH customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
part_supplier_summary AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
detailed_join AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.total_orders,
        co.total_spent,
        ps.total_available,
        ps.total_value,
        p.p_name,
        p.p_brand,
        p.p_type
    FROM customer_orders co
    JOIN lineitem l ON co.c_custkey = l.l_orderkey
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE co.total_spent > 10000 AND ps.total_available > 50
)
SELECT 
    d.c_name,
    COUNT(DISTINCT d.l_orderkey) AS total_orders,
    SUM(d.l_extendedprice) AS revenue,
    AVG(d.total_value) AS avg_part_value,
    COUNT(DISTINCT d.ps_partkey) AS unique_parts_provided
FROM detailed_join d
GROUP BY d.c_name
ORDER BY revenue DESC
LIMIT 10;
