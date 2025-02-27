WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COUNT(ps.ps_suppkey) AS SupplierCount
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS TotalOrders,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    p.p_name,
    p.SupplierCount,
    COALESCE(SD.TotalSupplyCost, 0) AS TotalSupplyCost,
    C.TotalOrders,
    C.TotalSpent,
    R.o_orderdate,
    R.o_orderstatus
FROM 
    PartDetails p
LEFT JOIN 
    SupplierDetails SD ON p.SupplierCount > 5 -- Only interested in parts supplied by more than 5 suppliers
LEFT JOIN 
    CustomerOrderSummary C ON C.TotalOrders > 10 -- Only include customers with more than 10 orders
JOIN 
    RankedOrders R ON R.rn = 1 -- Include latest order per status
WHERE 
    p.p_retailprice > 50.00
    AND (C.TotalSpent IS NULL OR C.TotalSpent > 1000.00)
ORDER BY 
    p.SupplierCount DESC, C.TotalSpent DESC;
