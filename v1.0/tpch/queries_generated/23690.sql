WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn,
        DATEDIFF(day, o.o_orderdate, GETDATE()) AS DaysSinceOrder
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (
            SELECT AVG(o2.o_totalprice) 
            FROM orders o2 
            WHERE o2.o_orderstatus = o.o_orderstatus
        )
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS TotalSupplyCost,
        COUNT(DISTINCT ps.ps_partkey) AS UniquePartsSupplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerPurchaseSummary AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS TotalSpent,
        COUNT(o.o_orderkey) AS OrdersCount
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IN ('F', 'C', 'P')
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    sd.s_name AS SupplierName,
    rk.o_orderkey,
    cp.TotalSpent,
    CASE 
        WHEN cp.TotalSpent IS NULL THEN 'No Purchases'
        WHEN cp.TotalSpent > 10000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS CustomerType,
    COALESCE(rk.DaysSinceOrder, -1) AS DaysSinceOrder,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier sd ON ps.ps_suppkey = sd.s_suppkey
LEFT JOIN 
    RankedOrders rk ON rk.o_orderkey = ps.ps_partkey
LEFT JOIN 
    CustomerPurchaseSummary cp ON cp.c_custkey = rk.o_orderkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
GROUP BY 
    p.p_partkey, p.p_name, sd.s_name, rk.o_orderkey, cp.TotalSpent, rk.DaysSinceOrder
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 5 OR cp.TotalSpent IS NULL
ORDER BY 
    TotalRevenue DESC, CustomerType ASC;
