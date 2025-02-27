WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F')
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS TotalAvailableQty,
        AVG(ps.ps_supplycost) AS AvgSupplyCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > 10000
    GROUP BY s.s_suppkey, s.s_name
),
SalesSummary AS (
    SELECT 
        c.c_custkey,
        s.r_name AS region,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales,
        COUNT(DISTINCT o.o_orderkey) AS OrderCount
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN supplier s ON l.l_suppkey = s.s_suppkey
    LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY c.c_custkey, s.r_name
),
FinalResults AS (
    SELECT 
        r.region,
        r.TotalSales,
        r.OrderCount,
        s.TotalAvailableQty,
        s.AvgSupplyCost
    FROM SalesSummary r
    LEFT JOIN SupplierInfo s ON r.region = (
        SELECT n.r_name
        FROM nation n
        WHERE n.n_nationkey = (
            SELECT DISTINCT s.s_nationkey
            FROM supplier s
            WHERE s.s_acctbal = (
                SELECT MAX(s2.s_acctbal)
                FROM supplier s2
            )
        )
    )
)
SELECT 
    region,
    TotalSales,
    OrderCount,
    COALESCE(TotalAvailableQty, 0) AS TotalAvailableQty,
    COALESCE(AvgSupplyCost, 0.00) AS AvgSupplyCost,
    CASE 
        WHEN TotalSales > 100000 THEN 'High Sales'
        WHEN TotalSales BETWEEN 50000 AND 100000 THEN 'Moderate Sales'
        ELSE 'Low Sales'
    END AS SalesCategory
FROM FinalResults
WHERE TotalSales IS NOT NULL
ORDER BY TotalSales DESC;

