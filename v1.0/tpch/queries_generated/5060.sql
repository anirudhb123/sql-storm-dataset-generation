WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts_supply,
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
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
LineItemStats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        SUM(l.l_quantity) AS total_quantity,
        l.l_shipmode
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey, l.l_shipmode
)

SELECT 
    ss.s_name,
    co.c_name,
    ls.l_shipmode,
    COUNT(DISTINCT co.c_custkey) AS total_customers,
    SUM(ls.revenue) AS total_revenue,
    SUM(ss.total_supply_value) AS total_supplier_value
FROM 
    SupplierStats ss
JOIN 
    CustomerOrders co ON ss.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps JOIN lineitem l ON ps.ps_partkey = l.l_partkey)
JOIN 
    LineItemStats ls ON ls.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey)
GROUP BY 
    ss.s_name, co.c_name, ls.l_shipmode
ORDER BY 
    total_revenue DESC, total_supplier_value DESC
LIMIT 10;
