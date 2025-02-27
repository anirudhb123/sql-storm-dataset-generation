WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
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
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_item_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    n.n_name,
    r.r_name,
    sp.s_name,
    cp.c_name,
    SUM(sp.total_supply_cost) AS total_supplier_cost,
    SUM(co.total_order_value) AS total_customer_order_value,
    SUM(od.total_line_item_value) AS total_order_detail_value
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    SupplierParts sp ON s.s_suppkey = sp.s_suppkey
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
JOIN 
    CustomerOrders co ON c.c_custkey = co.c_custkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    OrderDetails od ON o.o_orderkey = od.o_orderkey
GROUP BY 
    n.n_name, r.r_name, sp.s_name, cp.c_name
ORDER BY 
    total_supplier_cost DESC, total_customer_order_value DESC;
