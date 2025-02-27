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
customer_orders AS (
    SELECT 
        c.c_nationkey,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
),
nation_summary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COALESCE(cs.order_count, 0) AS customer_order_count,
        COALESCE(ss.supplier_count, 0) AS supplier_count,
        COALESCE(ss.total_supply_cost, 0) AS total_supply_cost
    FROM 
        nation n
    LEFT JOIN 
        customer_orders cs ON n.n_nationkey = cs.c_nationkey
    LEFT JOIN 
        supplier_summary ss ON n.n_nationkey = ss.n_nationkey
)
SELECT 
    ns.n_name,
    ns.customer_order_count,
    ns.supplier_count,
    ns.total_supply_cost,
    ROUND(ns.total_supply_cost / NULLIF(ns.customer_order_count, 0), 2) AS cost_per_order
FROM 
    nation_summary ns
WHERE 
    ns.customer_order_count > 10
ORDER BY 
    cost_per_order DESC
LIMIT 5;
