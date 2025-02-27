WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(MONTH, -6, GETDATE())
),
SupplierAvgCost AS (
    SELECT 
        ps.ps_partkey,
        AVG(ps.ps_supplycost) AS AvgSupplyCost
    FROM 
        partsupp ps
    INNER JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 1000
    GROUP BY 
        ps.ps_partkey
),
TopPartSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '2023-01-01'
    GROUP BY 
        l.l_partkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
),
RecentClaims AS (
    SELECT 
        l.l_orderkey,
        COUNT(l.l_linenumber) AS ClaimCount
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'R'
        AND l.l_shipdate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY 
        l.l_orderkey
    HAVING 
        COUNT(l.l_linenumber) > 5
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    COALESCE(SAC.AvgSupplyCost, 0) AS AvgSupplyCost,
    COALESCE(TPS.TotalSales, 0) AS TotalPartSales,
    R.orders
FROM 
    part p
LEFT JOIN 
    SupplierAvgCost SAC ON p.p_partkey = SAC.ps_partkey
LEFT JOIN 
    TopPartSales TPS ON p.p_partkey = TPS.l_partkey
LEFT JOIN 
    (SELECT 
         o.o_orderkey,
         STRING_AGG(R.o_orderpriority, ', ') AS orders
     FROM 
         RankedOrders R
     GROUP BY 
         o.o_orderkey
    ) AS R ON R.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey)
WHERE 
    p.p_size BETWEEN 10 AND 20
ORDER BY 
    p.p_retailprice DESC
OPTION (RECOMPILE);
