WITH TotalRevenue AS (
    SELECT 
        l_orderkey,
        SUM(l_extendedprice * (1 - l_discount)) AS revenue
    FROM 
        lineitem
    WHERE 
        l_shipdate >= DATE '1994-01-01' AND l_shipdate < DATE '1995-01-01'
    GROUP BY 
        l_orderkey
),
TopCustomers AS (
    SELECT 
        c_custkey,
        c_name,
        SUM(tr.revenue) AS total_revenue
    FROM 
        customer c
    JOIN 
        TotalRevenue tr ON c.c_custkey = (SELECT o_custkey FROM orders o WHERE o.o_orderkey = tr.l_orderkey)
    GROUP BY 
        c_custkey, c_name
    ORDER BY 
        total_revenue DESC
    LIMIT 10
),
SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(lp.l_extendedprice * (1 - lp.l_discount)) AS supplier_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem lp ON ps.ps_partkey = lp.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sp.supplier_revenue
    FROM 
        SupplierPerformance sp 
    JOIN 
        supplier s ON sp.s_suppkey = s.s_suppkey
    ORDER BY 
        sp.supplier_revenue DESC
    LIMIT 5
)
SELECT 
    tc.c_name AS Customer, 
    tc.total_revenue AS Customer_Revenue, 
    ts.s_name AS Supplier, 
    ts.supplier_revenue AS Supplier_Revenue
FROM 
    TopCustomers tc
CROSS JOIN 
    TopSuppliers ts
ORDER BY 
    tc.total_revenue DESC, 
    ts.supplier_revenue DESC;
