WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        COUNT(l.l_linenumber) AS total_lines,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
FinalReport AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        COALESCE(cs.total_orders, 0) AS total_orders,
        COALESCE(cs.total_spent, 0) AS total_spent,
        COALESCE(ss.total_available, 0) AS total_available,
        COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
        SUM(ls.net_revenue) AS total_revenue
    FROM 
        CustomerOrders cs
    FULL OUTER JOIN 
        SupplierStats ss ON cs.c_custkey % 100 = ss.s_suppkey % 100
    LEFT JOIN 
        LineItemSummary ls ON cs.total_orders = ls.total_lines
    GROUP BY 
        cs.c_custkey, cs.c_name, ss.total_available, ss.total_supply_cost
)
SELECT 
    fr.c_custkey,
    fr.c_name,
    fr.total_orders,
    fr.total_spent,
    fr.total_available,
    fr.total_supply_cost,
    fr.total_revenue,
    CASE 
        WHEN fr.total_orders > 0 THEN ROUND(fr.total_revenue / fr.total_orders, 2)
        ELSE NULL 
    END AS avg_revenue_per_order
FROM 
    FinalReport fr
ORDER BY 
    fr.total_spent DESC, fr.total_revenue DESC
LIMIT 100;
