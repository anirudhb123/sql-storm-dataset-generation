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
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderstatus IN ('F', 'O')
), SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS TotalAvailable,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 10000 
    GROUP BY 
        ps.ps_partkey
), ProcessedLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalLineItemValue,
        COUNT(*) AS LineItemCount
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '2023-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    n.n_name,
    SUM(TotalLineItemValue) AS TotalSales,
    AVG(TotalAvailable) AS AvgAvailability,
    COUNT(DISTINCT ro.o_orderkey) AS TotalOrders,
    COUNT(DISTINCT pl.l_orderkey) AS TotalProcessedLineItems
FROM 
    RankedOrders ro
JOIN 
    customer c ON ro.o_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    ProcessedLineItems pl ON ro.o_orderkey = pl.l_orderkey
JOIN 
    SupplierParts sp ON sp.ps_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = n.n_nationkey))
GROUP BY 
    n.n_name
HAVING 
    SUM(TotalLineItemValue) > 10000
ORDER BY 
    TotalSales DESC;
