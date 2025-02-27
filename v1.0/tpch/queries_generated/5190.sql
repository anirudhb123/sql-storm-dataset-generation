WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        sp.s_suppkey,
        sp.s_name,
        sp.total_available_quantity,
        sp.total_supply_cost
    FROM 
        SupplierParts sp
    ORDER BY 
        sp.total_supply_cost DESC
    LIMIT 10
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        COUNT(l.l_orderkey) AS lineitem_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice
)

SELECT 
    cu.c_custkey,
    cu.c_name,
    cu.o_orderkey,
    cu.o_totalprice,
    ts.s_suppkey,
    ts.s_name,
    ts.total_available_quantity,
    ts.total_supply_cost,
    cu.lineitem_count
FROM 
    CustomerOrders cu
JOIN 
    TopSuppliers ts ON cu.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_suppkey = ts.s_suppkey)
ORDER BY 
    cu.o_totalprice DESC, ts.total_supply_cost DESC
LIMIT 50;
