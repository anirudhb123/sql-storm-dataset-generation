WITH SupplierTotalCost AS (
    SELECT 
        ps.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM 
        partsupp ps
    GROUP BY 
        ps.s_suppkey
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        stc.total_cost,
        ROW_NUMBER() OVER (ORDER BY stc.total_cost DESC) AS rank
    FROM 
        supplier s
    JOIN 
        SupplierTotalCost stc ON s.s_suppkey = stc.s_suppkey
    WHERE 
        stc.total_cost > 10000
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, 
        o.o_orderstatus
)
SELECT 
    n.n_name,
    COALESCE(AVG(c.total_spent), 0) AS avg_customer_spent,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied,
    SUM(od.revenue) AS total_revenue,
    s.s_name AS top_supplier
FROM 
    nation n
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    CustomerOrderStats cos ON c.c_custkey = cos.c_custkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    partsupp ps ON ps.ps_suppkey IN (SELECT s_suppkey FROM TopSuppliers WHERE rank <= 5)
LEFT JOIN 
    OrderDetails od ON o.o_orderkey = od.o_orderkey
JOIN 
    TopSuppliers s ON s.s_suppkey = ps.ps_suppkey
GROUP BY 
    n.n_name, s.s_name
HAVING 
    AVG(c.total_spent) IS NOT NULL
ORDER BY 
    total_revenue DESC, avg_customer_spent DESC;
