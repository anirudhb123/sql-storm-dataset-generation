WITH SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS TotalPartsSupplied,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS TotalSpent,
        COUNT(DISTINCT o.o_orderkey) AS TotalOrders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS Rnk
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
),
LineItemAnalysis AS (
    SELECT 
        l.l_orderkey,
        l.l_returnflag,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS NetSales,
        AVG(l.l_quantity) AS AvgQuantity
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN '2023-01-01' AND '2023-10-31'
    GROUP BY 
        l.l_orderkey, l.l_returnflag
)
SELECT 
    sp.s_name,
    sp.TotalPartsSupplied,
    sp.TotalSupplyCost,
    COALESCE(cu.TotalSpent, 0) AS CustomerTotalSpent,
    COALESCE(cu.TotalOrders, 0) AS TotalOrdersByCustomer,
    li.NetSales,
    li.AvgQuantity,
    ho.o_orderdate,
    ho.o_totalprice
FROM 
    SupplierPerformance sp
LEFT JOIN 
    CustomerOrders cu ON sp.TotalPartsSupplied > 10
LEFT JOIN 
    LineItemAnalysis li ON li.l_orderkey IN (SELECT o_orderkey FROM HighValueOrders WHERE Rnk <= 5)
LEFT JOIN 
    HighValueOrders ho ON ho.o_orderkey = li.l_orderkey
WHERE 
    sp.TotalSupplyCost > (SELECT AVG(TotalSupplyCost) FROM SupplierPerformance)
ORDER BY 
    sp.TotalSupplyCost DESC, cu.TotalSpent DESC;
