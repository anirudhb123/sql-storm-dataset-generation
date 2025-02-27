WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2022-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_availqty) AS TotalAvailableQuantity
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        CASE 
            WHEN c.c_acctbal > 10000 THEN 'High Value'
            ELSE 'Regular'
        END AS CustomerValueSegment
    FROM customer c
),
NationsWithRegions AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name
    FROM nation n
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    c.c_name,
    c.c_acctbal,
    COALESCE(SD.TotalAvailableQuantity, 0) AS SupplierTotalAvailability,
    COUNT(o.o_orderkey) AS TotalOrders,
    SUM(o.o_totalprice) AS SumTotalOrderPrices,
    n.region_name
FROM CustomerSummary c
LEFT JOIN RankedOrders o ON c.c_custkey = o.o_orderkey
LEFT JOIN SupplierDetails SD ON c.c_custkey = SD.s_nationkey
JOIN NationsWithRegions n ON c.c_nationkey = n.n_nationkey
WHERE 
    c.c_acctbal IS NOT NULL AND 
    (o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL) AND 
    (SD.TotalAvailableQuantity IS NULL OR SD.TotalAvailableQuantity > 100)
GROUP BY 
    c.c_name, 
    c.c_acctbal, 
    SD.TotalAvailableQuantity, 
    n.region_name
HAVING 
    SUM(o.o_totalprice) > 5000
ORDER BY 
    c.c_acctbal DESC,
    TotalOrders DESC;
