WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalAmount,
        DENSE_RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATEADD(MONTH, -6, GETDATE())
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    r.r_name AS Region,
    n.n_name AS Nation,
    SUM(ls.TotalAmount) AS TotalSales,
    COUNT(DISTINCT o.o_orderkey) AS NumberOfOrders,
    COALESCE(SUM(rs.TotalSupplyCost), 0) AS TotalSupplierCost
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    RecentOrders ls ON c.c_custkey = ls.o_custkey
LEFT JOIN 
    RankedSuppliers rs ON rs.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        WHERE ps.ps_partkey IN (
            SELECT p.p_partkey
            FROM part p
            WHERE p.p_size = (SELECT MAX(p_size) FROM part)
        )
    )
WHERE 
    n.n_name IS NOT NULL 
    AND r.r_name IS NOT NULL
GROUP BY 
    r.r_name, n.n_name
HAVING 
    SUM(ls.TotalAmount) IS NOT NULL
ORDER BY 
    TotalSales DESC;
