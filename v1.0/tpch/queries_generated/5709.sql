WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        o.o_orderstatus, 
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
), 
CustomerStats AS (
    SELECT 
        c.c_nationkey, 
        SUM(o.o_totalprice) AS TotalSpent, 
        COUNT(o.o_orderkey) AS OrdersCount
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
), 
SupplierStats AS (
    SELECT 
        s.s_nationkey, 
        COUNT(DISTINCT ps.ps_partkey) AS SupplierPartsCount, 
        SUM(ps.ps_supplycost) AS TotalSupplyCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
), 
NationPerformance AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        COALESCE(cs.TotalSpent, 0) AS NationTotalSpent, 
        COALESCE(cs.OrdersCount, 0) AS NationOrdersCount, 
        COALESCE(ss.SupplierPartsCount, 0) AS NationSupplierPartsCount, 
        COALESCE(ss.TotalSupplyCost, 0) AS NationTotalSupplyCost
    FROM 
        nation n
    LEFT JOIN 
        CustomerStats cs ON n.n_nationkey = cs.c_nationkey
    LEFT JOIN 
        SupplierStats ss ON n.n_nationkey = ss.s_nationkey
)
SELECT 
    np.n_nationkey, 
    np.n_name, 
    np.NationTotalSpent, 
    np.NationOrdersCount, 
    np.NationSupplierPartsCount, 
    np.NationTotalSupplyCost, 
    COUNT(ro.o_orderkey) AS HighPriorityOrders
FROM 
    NationPerformance np
LEFT JOIN 
    RankedOrders ro ON np.n_nationkey = (SELECT c.c_nationkey FROM customer c JOIN orders o ON c.c_custkey = o.o_custkey WHERE o.o_orderkey = ro.o_orderkey)
WHERE 
    ro.OrderRank <= 10
GROUP BY 
    np.n_nationkey, 
    np.n_name, 
    np.NationTotalSpent, 
    np.NationOrdersCount, 
    np.NationSupplierPartsCount, 
    np.NationTotalSupplyCost
ORDER BY 
    np.NationTotalSpent DESC;
