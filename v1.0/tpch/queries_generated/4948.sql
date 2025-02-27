WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_available_qty, 
        AVG(ps.ps_supplycost) AS avg_supply_cost
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
OrderLineDetails AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)

SELECT 
    r.r_name AS region_name, 
    ns.n_name AS nation_name, 
    cs.c_name AS customer_name, 
    ss.s_name AS supplier_name, 
    COALESCE(cs.total_orders, 0) AS customer_orders_count, 
    COALESCE(cs.total_spent, 0) AS total_spent_by_customer,
    ss.total_available_qty, 
    ss.avg_supply_cost,
    COUNT(DISTINCT od.o_orderkey) AS distinct_orders_count,
    SUM(od.net_revenue) AS total_net_revenue 
FROM 
    region r
JOIN 
    nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN 
    customer cs ON ns.n_nationkey = cs.c_nationkey
LEFT JOIN 
    supplier ss ON ns.n_nationkey = ss.s_nationkey
LEFT JOIN 
    OrderLineDetails od ON ss.s_suppkey = od.o_orderkey
GROUP BY 
    r.r_name, ns.n_name, cs.c_name, ss.s_name, ss.total_available_qty, ss.avg_supply_cost
HAVING 
    SUM(COALESCE(od.net_revenue, 0)) > (SELECT AVG(total_net_revenue) FROM OrderLineDetails)
ORDER BY 
    region_name, nation_name, customer_name;
