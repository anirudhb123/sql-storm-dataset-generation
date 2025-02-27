WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name
),
TopSuppliers AS (
    SELECT 
        s_rank.s_name,
        s_rank.TotalSupplyCost,
        c.c_name AS CustomerName,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice
    FROM 
        RankedSuppliers s_rank
    JOIN 
        orders o ON o.o_orderkey IN (
            SELECT l.l_orderkey 
            FROM lineitem l 
            JOIN partsupp ps ON l.l_partkey = ps.ps_partkey 
            WHERE ps.ps_suppkey IN (
                SELECT s_suppkey 
                FROM supplier 
                WHERE s_name = s_rank.s_name
            )
        )
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        s_rank.Rank <= 5
)
SELECT 
    TopSuppliers.s_name,
    TopSuppliers.TotalSupplyCost,
    COUNT(TopSuppliers.o_orderkey) AS TotalOrders,
    SUM(TopSuppliers.o_totalprice) AS TotalRevenue
FROM 
    TopSuppliers
GROUP BY 
    TopSuppliers.s_name, 
    TopSuppliers.TotalSupplyCost
ORDER BY 
    TotalRevenue DESC;
