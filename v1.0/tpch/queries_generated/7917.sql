WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts, 
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
OrderLineItemStats AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.r_name,
    ss.s_name,
    cs.c_name,
    COUNT(DISTINCT ol.o_orderkey) AS order_count,
    SUM(ol.total_revenue) AS total_revenue,
    AVG(ss.total_supply_cost) AS avg_supply_cost,
    SUM(cs.total_spent) AS total_spent_by_customer
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    SupplierStats ss ON s.s_suppkey = ss.s_suppkey
JOIN 
    CustomerOrders cs ON ss.unique_parts > 0
JOIN 
    orders ol ON ol.o_custkey = cs.c_custkey
GROUP BY 
    r.r_name, ss.s_name, cs.c_name
ORDER BY 
    total_revenue DESC, order_count DESC
LIMIT 100;
