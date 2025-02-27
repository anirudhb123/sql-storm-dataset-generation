WITH supplier_stats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),

customer_orders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),

region_supplier AS (
    SELECT
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_acctbal
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name
)

SELECT 
    rs.r_name,
    COALESCE(sp.total_parts, 0) AS supplier_parts,
    COALESCE(sp.total_value, 0) AS supplier_value,
    COALESCE(co.order_count, 0) AS customer_orders,
    COALESCE(co.total_spent, 0.00) AS customer_spending,
    CASE 
        WHEN COALESCE(co.total_spent, 0) > 0 
        THEN ROUND(COALESCE(sp.total_value, 0) / COALESCE(co.total_spent, 1), 2)
        ELSE 0 
    END AS value_per_order
FROM region_supplier rs
LEFT JOIN supplier_stats sp ON rs.supplier_count > 0 AND rs.supplier_count * 2 > sp.total_parts
LEFT JOIN customer_orders co ON co.order_count > 1 AND co.total_spent > 1000
ORDER BY rs.r_name, supplier_parts DESC, customer_orders DESC;
