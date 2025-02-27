WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        COUNT(DISTINCT ps.ps_partkey) AS UniquePartsSupplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > 1000.00
    GROUP BY 
        s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS TotalOrderValue,
        COUNT(o.o_orderkey) AS OrderCount
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
LineItemAnalysis AS (
    SELECT 
        l.l_orderkey,
        COUNT(*) AS LineItemCount,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS NetRevenue
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
)

SELECT 
    n.n_name,
    COUNT(DISTINCT s.s_suppkey) AS SupplierCount,
    COALESCE(SUM(TS.TotalSupplyCost), 0) AS TotalSupplyCost,
    COALESCE(SUM(CO.TotalOrderValue), 0) AS TotalCustomerOrderValue,
    COALESCE(SUM(LA.NetRevenue), 0) AS TotalNetRevenue,
    AVG(COALESCE(CU.OrderCount, 0)) AS AvgCustomerOrders,
    MAX(COALESCE(PS.UniquePartsSupplied, 0)) AS MaxUniquePartsSupplied
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierStats TS ON s.s_suppkey = TS.s_suppkey
LEFT JOIN 
    CustomerOrders CO ON s.s_nationkey = CO.c_custkey 
LEFT JOIN 
    LineItemAnalysis LA ON CO.c_custkey = LA.l_orderkey 
LEFT JOIN 
    (SELECT 
         c.c_custkey,
         COUNT(o.o_orderkey) AS OrderCount
     FROM 
         customer c
     LEFT JOIN 
         orders o ON c.c_custkey = o.o_custkey
     WHERE 
         o.o_orderstatus = 'F' 
     GROUP BY 
         c.c_custkey) CU ON CU.c_custkey = s.s_nationkey
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 3
ORDER BY 
    TotalSupplyCost DESC, 
    n.n_name;
