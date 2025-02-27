WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate > '1996-01-01' 
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
RelevantSuppliers AS (
    SELECT 
        s.s_nationkey, 
        ss.s_name, 
        ss.total_available_quantity,
        ss.avg_supply_cost
    FROM 
        SupplierStats ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
),
TopCustomers AS (
    SELECT 
        DISTINCT c.c_custkey, 
        c.c_name, 
        os.total_order_value
    FROM 
        customer c
    JOIN 
        OrderSummary os ON c.c_custkey = os.o_custkey
    WHERE 
        os.total_order_value > (SELECT AVG(total_order_value) FROM OrderSummary)
)
SELECT 
    r.r_name, 
    COUNT(DISTINCT rs.total_available_quantity) AS supplier_count,
    SUM(ts.total_order_value) AS total_sales_value
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    RelevantSuppliers rs ON n.n_nationkey = rs.s_nationkey
LEFT JOIN 
    TopCustomers ts ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = ts.c_custkey)
GROUP BY 
    r.r_name
HAVING 
    SUM(ts.total_order_value) IS NOT NULL
ORDER BY 
    total_sales_value DESC;