WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
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
NationSupplier AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
),
SalesSummary AS (
    SELECT 
        l.l_shipmode,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        l.l_shipmode
)
SELECT 
    n.n_name AS Nation,
    ss.s_name AS Supplier,
    cs.c_name AS Customer,
    cs.total_orders AS Total_Orders,
    cs.total_spent AS Total_Spent,
    ss.total_available_qty AS Total_Available_Quantity,
    ss.avg_supply_cost AS Avg_Supply_Cost,
    s.l_shipmode AS Shipping_Mode,
    ss.part_count AS Distinct_Parts_Supplied,
    ss.total_available_qty * COALESCE(cs.total_spent, 0) AS Value_Added
FROM 
    NationSupplier n
LEFT JOIN 
    SupplierStats ss ON n.supplier_count > ss.part_count
LEFT JOIN 
    CustomerOrders cs ON ss.total_available_qty > cs.total_orders
CROSS JOIN 
    SalesSummary s
WHERE 
    (n.n_name LIKE 'A%' OR n.n_name LIKE 'B%')
    AND (ss.avg_supply_cost IS NOT NULL OR cs.total_spent IS NULL)
ORDER BY 
    Value_Added DESC
LIMIT 50
