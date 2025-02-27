WITH SupplierOrderSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderDetails AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS customer_total_spent,
        COUNT(o.o_orderkey) AS order_count
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
        sos.total_order_value,
        ROW_NUMBER() OVER (ORDER BY sos.total_order_value DESC) AS rank
    FROM 
        SupplierOrderSummary sos
    WHERE 
        sos.total_order_value IS NOT NULL
)
SELECT 
    cu.c_custkey,
    cu.c_name,
    cu.customer_total_spent,
    COALESCE(ts.s_name, 'No Supplier') AS top_supplier_name,
    COALESCE(ts.total_order_value, 0) AS supplier_total_orders
FROM 
    CustomerOrderDetails cu
LEFT JOIN 
    TopSuppliers ts ON cu.order_count >= 10 AND ts.rank = 1
WHERE 
    cu.customer_total_spent > (SELECT AVG(customer_total_spent) FROM CustomerOrderDetails WHERE order_count > 5)
ORDER BY 
    cu.customer_total_spent DESC;
