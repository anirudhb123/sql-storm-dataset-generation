
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS StatusRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS TotalAvailableQuantity,
        AVG(ps.ps_supplycost) AS AvgSupplyCost,
        STRING_AGG(DISTINCT p.p_name, ', ') AS PartNames
    FROM 
        partsupp ps
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS TotalOrders,
        SUM(o.o_totalprice) AS TotalSpent,
        MAX(o.o_orderdate) AS LastOrderDate
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_acctbal > 0.00
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.o_orderkey AS OrderID,
    r.o_totalprice AS TotalPrice,
    COALESCE(cs.TotalOrders, 0) AS CustomerOrderCount,
    COALESCE(ps.TotalAvailableQuantity, 0) AS SupplierAvailableQuantity,
    ps.PartNames,
    CASE 
        WHEN r.StatusRank = 1 THEN 'Top Order'
        WHEN r.StatusRank BETWEEN 2 AND 5 THEN 'High Order'
        ELSE 'Regular Order'
    END AS OrderStatus,
    SUM(CASE 
        WHEN l.l_discount > 0.10 THEN l.l_extendedprice * (1 - l.l_discount)
        ELSE 0 
    END) AS TotalDiscountedPrice
FROM 
    RankedOrders r
LEFT JOIN 
    CustomerOrderStats cs ON cs.TotalSpent > 1000 AND cs.LastOrderDate >= CURRENT_DATE - INTERVAL '30 days'
JOIN 
    lineitem l ON r.o_orderkey = l.l_orderkey
FULL OUTER JOIN 
    SupplierParts ps ON ps.ps_partkey = l.l_partkey
GROUP BY 
    r.o_orderkey, r.o_totalprice, cs.TotalOrders, ps.TotalAvailableQuantity, ps.PartNames, r.StatusRank
HAVING 
    SUM(l.l_quantity) IS NULL OR SUM(l.l_quantity) > 100
ORDER BY 
    r.o_orderkey DESC;
