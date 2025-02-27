WITH supplier_info AS (
    SELECT 
        s.s_name, 
        r.r_name AS region_name, 
        COUNT(DISTINCT ps.ps_partkey) AS part_count, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        STRING_AGG(DISTINCT CONCAT(p.p_name, ' (' , p.p_size, ' ', p.p_container, ')'), ', ') AS part_details
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY s.s_name, r.r_name
),
customer_orders AS (
    SELECT 
        c.c_name, 
        c.c_nationkey, 
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_name, c.c_nationkey
),
combined_info AS (
    SELECT 
        si.s_name AS supplier_name,
        si.region_name,
        si.part_count,
        si.total_cost,
        COALESCE(co.total_spent, 0) AS customer_spending,
        co.order_count
    FROM supplier_info si
    LEFT JOIN customer_orders co ON si.part_count > co.order_count
)
SELECT 
    ci.supplier_name, 
    ci.region_name, 
    ci.part_count, 
    ci.total_cost, 
    ci.customer_spending, 
    ci.order_count
FROM combined_info ci
WHERE ci.total_cost > 10000
ORDER BY ci.total_cost DESC, ci.part_count DESC;
