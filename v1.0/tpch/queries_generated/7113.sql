WITH Summary AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT c.c_custkey) AS total_customers,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        COUNT(DISTINCT l.l_orderkey) AS total_lineitems
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        customer c ON s.s_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        n.n_name, r.r_name
)
SELECT 
    nation_name,
    region_name,
    total_avail_qty,
    total_supply_cost,
    total_customers,
    total_orders,
    total_lineitems,
    total_supply_cost / NULLIF(total_avail_qty, 0) AS avg_supply_cost_per_quantity,
    CASE 
        WHEN total_orders = 0 THEN 0 
        ELSE CAST(total_lineitems AS DECIMAL) / total_orders 
    END AS avg_lineitems_per_order
FROM 
    Summary
ORDER BY 
    region_name, nation_name;
