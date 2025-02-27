WITH RankedSuppliers AS (
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
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        rs.total_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        supplier s ON rs.s_suppkey = s.s_suppkey
    ORDER BY 
        rs.total_cost DESC
    LIMIT 10
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
),
OrderLineItem AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        orders o 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    s.s_name AS Supplier_Name,
    c.c_name AS Customer_Name,
    os.order_count,
    os.total_spent,
    COUNT(oli.o_orderkey) AS number_of_orders,
    SUM(oli.revenue) AS total_revenue
FROM 
    TopSuppliers s
JOIN 
    CustomerOrderSummary os ON os.total_spent > 10000
JOIN 
    OrderLineItem oli ON oli.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = os.c_custkey)
GROUP BY 
    s.s_name, c.c_name, os.order_count, os.total_spent
ORDER BY 
    total_revenue DESC;
