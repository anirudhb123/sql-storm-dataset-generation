WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
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
        COUNT(o.o_orderkey) AS num_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
OrderLineItems AS (
    SELECT 
        o.o_orderkey,
        l.l_partkey,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, l.l_partkey
)
SELECT 
    sp.s_name,
    co.c_name,
    ol.total_revenue,
    ol.total_quantity,
    sp.total_available_quantity,
    sp.total_supply_value
FROM 
    SupplierParts sp
JOIN 
    OrderLineItems ol ON sp.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = ol.l_partkey 
        ORDER BY ps.ps_supplycost 
        LIMIT 1
    )
JOIN 
    CustomerOrders co ON co.num_orders > 5
WHERE 
    sp.total_supply_value > 100000
ORDER BY 
    ol.total_revenue DESC
LIMIT 10;
