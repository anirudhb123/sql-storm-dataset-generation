WITH RECURSIVE TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
    ORDER BY 
        TotalCost DESC
    LIMIT 10
),
MonthlySales AS (
    SELECT 
        DATE_TRUNC('month', o.o_orderdate) AS SalesMonth, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        SalesMonth
),
CustomerRegion AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        r.r_name,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, r.r_name
)
SELECT 
    cr.c_name,
    cr.r_name,
    COALESCE(cr.TotalSpent, 0) AS TotalSpent,
    COALESCE(ms.TotalSales, 0) AS MonthlySales,
    ts.TotalCost AS TopSupplierCost
FROM 
    CustomerRegion cr
LEFT JOIN 
    MonthlySales ms ON cr.TotalSpent > 1000
LEFT JOIN 
    TopSuppliers ts ON cr.c_custkey = ts.s_suppkey
WHERE 
    cr.TotalSpent IS NOT NULL
ORDER BY 
    cr.TotalSpent DESC, ts.TotalCost DESC;

