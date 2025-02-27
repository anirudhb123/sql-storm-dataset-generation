WITH supplier_summary AS (
    SELECT 
        s.n_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.n_nationkey
),
order_summary AS (
    SELECT 
        c.c_nationkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
),
combined_summary AS (
    SELECT 
        r.r_name,
        ss.total_supply_cost,
        ss.supplier_count,
        os.total_orders,
        os.total_order_value
    FROM 
        region r
    LEFT JOIN 
        supplier_summary ss ON r.r_regionkey = ss.n_nationkey
    LEFT JOIN 
        order_summary os ON r.r_regionkey = os.c_nationkey
)
SELECT 
    r_name,
    total_supply_cost,
    supplier_count,
    total_orders,
    total_order_value,
    (COALESCE(total_order_value, 0) / NULLIF(supplier_count, 0)) AS average_order_value_per_supplier
FROM 
    combined_summary
ORDER BY 
    total_supply_cost DESC, 
    total_order_value DESC
LIMIT 10;
