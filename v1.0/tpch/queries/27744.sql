WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name,
        rs.s_name,
        rs.TotalCost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON n.n_nationkey = rs.s_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.Rank <= 3
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cus.c_name,
    cus.OrderCount,
    cus.TotalSpent,
    ts.r_name AS SupplierRegion,
    ts.s_name AS TopSupplier,
    ts.TotalCost AS SupplierCost
FROM 
    CustomerOrderSummary cus
LEFT JOIN 
    TopSuppliers ts ON ts.TotalCost = (
        SELECT MAX(ts2.TotalCost)
        FROM TopSuppliers ts2
        WHERE ts2.r_name = (
            SELECT r.r_name
            FROM nation n
            JOIN region r ON n.n_regionkey = r.r_regionkey
            WHERE n.n_nationkey = (
                SELECT c.c_nationkey
                FROM customer c
                WHERE c.c_custkey = cus.c_custkey
            )
        )
    )
ORDER BY 
    cus.TotalSpent DESC, 
    SupplierRegion, 
    TopSupplier;
