WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierParts AS (
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
RegionStats AS (
    SELECT 
        n.n_nationkey,
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, r.r_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_linenumber) AS line_item_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    COALESCE(cu.c_name, 'Unknown Customer') AS customer_name,
    cu.total_spent,
    cu.order_count,
    cu.last_order_date,
    s.s_name AS supplier_name,
    sp.total_available_qty,
    sp.avg_supply_cost,
    r.r_name AS region_name,
    rs.supplier_count,
    od.line_item_count,
    od.total_line_price
FROM 
    CustomerOrders cu
LEFT JOIN 
    SupplierParts sp ON cu.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
LEFT JOIN 
    RegionStats rs ON rs.supplier_count > 0
LEFT JOIN 
    OrderDetails od ON od.total_line_price > 1000
ORDER BY 
    cu.total_spent DESC, sp.avg_supply_cost ASC;
