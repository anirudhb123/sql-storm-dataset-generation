
WITH SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyValue,
        COUNT(DISTINCT ps.ps_partkey) AS UniquePartsSupplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sp.TotalSupplyValue,
        sp.UniquePartsSupplied,
        RANK() OVER (ORDER BY sp.TotalSupplyValue DESC) AS Rank
    FROM 
        SupplierPerformance sp
    JOIN 
        supplier s ON sp.s_suppkey = s.s_suppkey
    WHERE 
        sp.UniquePartsSupplied > 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalOrderValue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '1997-01-01'
        AND l.l_shipdate < '1998-01-01'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
AggregateCustomerData AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        AVG(co.TotalOrderValue) AS AvgOrderValue,
        COUNT(co.o_orderkey) AS TotalOrders
    FROM 
        customer c
    LEFT JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    acd.c_custkey,
    acd.c_name,
    acd.AvgOrderValue,
    acd.TotalOrders,
    ts.s_suppkey,
    ts.s_name,
    ts.TotalSupplyValue
FROM 
    AggregateCustomerData acd
FULL OUTER JOIN 
    TopSuppliers ts ON acd.TotalOrders > 5 AND ts.UniquePartsSupplied > 10
WHERE 
    (acd.AvgOrderValue IS NOT NULL OR ts.TotalSupplyValue IS NOT NULL)
    AND (acd.c_name LIKE 'A%' OR ts.s_name LIKE 'B%')
ORDER BY 
    acd.AvgOrderValue DESC,
    ts.TotalSupplyValue ASC;
