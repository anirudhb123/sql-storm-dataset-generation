WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS SupplierRank
    FROM 
        supplier s
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSales
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
PartSupplierStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS TotalAvailable,
        AVG(ps.ps_supplycost) AS AvgSupplyCost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    c.c_name,
    ps.p_name,
    COALESCE(o.OrderCount, 0) AS OrderCount,
    ps.TotalAvailable,
    ps.AvgSupplyCost,
    RANK() OVER (PARTITION BY ps.p_partkey ORDER BY ps.AvgSupplyCost DESC) AS CostRanking,
    CASE 
        WHEN ps.AvgSupplyCost IS NULL THEN 'No Cost Data'
        ELSE 
            CASE 
                WHEN ps.AvgSupplyCost < 10 THEN 'Cheap'
                WHEN ps.AvgSupplyCost BETWEEN 10 AND 50 THEN 'Moderate'
                ELSE 'Expensive'
            END
    END AS CostCategory,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS ReturnCount,
    MAX(s.s_name) FILTER (WHERE rs.SupplierRank <= 3) AS TopSupplier
FROM 
    CustomerOrders o
FULL OUTER JOIN 
    customer c ON o.c_custkey = c.c_custkey
JOIN 
    PartSupplierStats ps ON ps.p_partkey IN (
        SELECT 
            ps1.ps_partkey 
        FROM 
            partsupp ps1 
        WHERE 
            ps1.ps_supplycost < (SELECT AVG(ps2.ps_supplycost) FROM partsupp ps2)
    )
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    RankedSuppliers rs ON rs.s_suppkey = l.l_suppkey
GROUP BY 
    c.c_name, ps.p_name, ps.TotalAvailable, ps.AvgSupplyCost
ORDER BY 
    CostRanking, c.c_name;
