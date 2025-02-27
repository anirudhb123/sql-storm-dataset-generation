WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal,
        n.n_name
    FROM
        RankedSuppliers rs
    JOIN
        nation n ON rs.s_nationkey = n.n_nationkey
    WHERE
        rs.rank <= 3
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cus.c_name,
    cus.total_spent,
    sup.s_name,
    sup.s_acctbal,
    CASE 
        WHEN cus.total_spent > 1000 THEN 'High Value'
        WHEN cus.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category,
    COALESCE(CAST(REGEXP_REPLACE(sup.s_name, 'Supplier', 'Partner') AS VARCHAR), 'None') AS adjusted_supplier_name
FROM 
    CustomerOrderSummary cus
LEFT JOIN 
    TopSuppliers sup ON cus.custkey = sup.s_suppkey 
WHERE 
    cus.total_orders > 0
ORDER BY 
    cus.total_spent DESC;
