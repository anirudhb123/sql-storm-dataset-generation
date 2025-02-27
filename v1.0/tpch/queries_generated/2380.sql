WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_availqty * ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighSpendingCustomers AS (
    SELECT 
        cus.c_custkey, 
        cus.c_name, 
        cus.total_spent
    FROM 
        CustomerOrderSummary cus
    WHERE 
        cus.total_spent > (SELECT AVG(total_spent) FROM CustomerOrderSummary)
)
SELECT 
    r.r_name, 
    COUNT(DISTINCT h.c_custkey) AS high_spending_customers,
    SUM(s.total_cost) AS total_supplier_cost
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
LEFT JOIN 
    HighSpendingCustomers h ON s.s_nationkey = h.c_custkey
GROUP BY 
    r.r_name
ORDER BY 
    total_supplier_cost DESC;
