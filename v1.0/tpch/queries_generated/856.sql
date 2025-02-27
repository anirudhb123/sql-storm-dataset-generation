WITH TotalSales AS (
    SELECT
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSalesAmount
    FROM
        lineitem l
    GROUP BY
        l.l_orderkey
),
SupplierStats AS (
    SELECT
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS UniquePartsSupplied,
        AVG(ps.ps_supplycost) AS AverageSupplyCost,
        SUM(ps.ps_availqty) AS TotalAvailableQuantity
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey
),
OrderDetails AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS OrderTotal,
        COUNT(DISTINCT o.o_custkey) AS DistinctCustomers,
        MAX(l.l_shipdate) AS LastShipDate
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey
),
RankedOrders AS (
    SELECT
        od.o_orderkey,
        od.OrderTotal,
        od.DistinctCustomers,
        od.LastShipDate,
        RANK() OVER (ORDER BY od.OrderTotal DESC) AS OrderRank
    FROM
        OrderDetails od
)
SELECT
    r.r_name AS RegionName,
    n.n_name AS NationName,
    COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
    SUM(ts.TotalSalesAmount) AS RegionTotalSales,
    AVG(su.UniquePartsSupplied) AS AvgUniquePartsSupplied,
    COUNT(DISTINCT rs.o_orderkey) AS RankedOrderCount
FROM
    region r
JOIN
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN
    TotalSales ts ON ts.l_orderkey = ps.ps_partkey
LEFT JOIN
    RankedOrders rs ON s.s_suppkey = rs.o_orderkey
WHERE
    r.r_name NOT LIKE '%test%' AND
    (s.s_acctbal IS NULL OR s.s_acctbal > 1000)
GROUP BY
    r.r_name, n.n_name
HAVING
    SUM(ts.TotalSalesAmount) > 50000
ORDER BY
    RegionTotalSales DESC, NationName ASC;
