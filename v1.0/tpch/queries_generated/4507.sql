WITH SupplierCosts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
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
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
RankedSuppliers AS (
    SELECT 
        s.s_name,
        RANK() OVER (ORDER BY sc.total_cost DESC) AS rank_order
    FROM 
        SupplierCosts sc
    JOIN 
        supplier s ON s.s_suppkey = sc.s_suppkey
)
SELECT 
    c.c_name AS customer_name,
    co.order_count,
    co.total_spent,
    rs.s_name AS supplier_name,
    rs.rank_order,
    CASE 
        WHEN co.total_spent > 5000 THEN 'High Value'
        WHEN co.total_spent BETWEEN 1000 AND 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment,
    NULLIF(co.order_count, 0) AS non_zero_order_count
FROM 
    CustomerOrders co
JOIN 
    RankedSuppliers rs ON co.order_count > 0
LEFT JOIN 
    supplier s ON co.c_custkey = s.s_nationkey
WHERE 
    rs.rank_order <= 5
ORDER BY 
    co.total_spent DESC, customer_name;
