WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_avail_qty, 
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerTotals AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent,
        MIN(o.o_orderdate) AS first_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    GROUP BY 
        c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        ss.total_avail_qty, 
        ss.avg_supply_cost
    FROM 
        SupplierStats ss
    WHERE 
        ss.rn = 1 -- Top supplier per nation
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_orderstatus, 
        o.o_totalprice,
        o.o_orderdate,
        CASE WHEN o.o_orderstatus = 'F' THEN 'Finalized' ELSE 'Not Finalized' END AS order_status_description
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2023-01-01' 
        AND o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
)
SELECT 
    ct.c_name AS customer_name, 
    ct.total_spent AS total_spent, 
    ts.s_name AS top_supplier_name, 
    ts.total_avail_qty AS supplier_avail_qty, 
    ts.avg_supply_cost AS supplier_avg_cost,
    fo.o_orderkey, 
    fo.order_status_description,
    DATEDIFF(CURDATE(), ct.first_order_date) AS days_since_first_order
FROM 
    CustomerTotals ct
LEFT JOIN 
    FilteredOrders fo ON ct.c_custkey = fo.o_custkey
JOIN 
    TopSuppliers ts ON ts.s_suppkey = fo.o_orderkey
WHERE 
    ct.total_spent IS NOT NULL
ORDER BY 
    ct.total_spent DESC, 
    ts.total_avail_qty DESC;
