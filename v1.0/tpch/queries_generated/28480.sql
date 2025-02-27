WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
CombinedReport AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name AS supplier_name,
        ss.total_available_qty,
        ss.total_cost,
        cos.c_custkey,
        cos.c_name AS customer_name,
        cos.total_orders,
        cos.total_spent
    FROM 
        SupplierSummary ss
    LEFT JOIN 
        CustomerOrderSummary cos ON ss.total_available_qty > 1000 AND cos.total_spent > 5000
)
SELECT 
    supplier_name,
    total_available_qty,
    total_cost,
    customer_name,
    total_orders,
    total_spent
FROM 
    CombinedReport
WHERE 
    total_available_qty > 5000 
ORDER BY 
    total_spent DESC, total_available_qty DESC;
