WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        orders o
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        SUM(ps.ps_availqty) AS TotalAvailableQty,
        COUNT(DISTINCT ps.ps_suppkey) AS UniqueSuppliers,
        MAX(ps.ps_supplycost) AS MaxSupplyCost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        SUM(o.o_totalprice) AS TotalSpent,
        COUNT(o.o_orderkey) AS OrdersCount
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        co.TotalSpent,
        co.OrdersCount
    FROM 
        customer c
    JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
    WHERE 
        co.TotalSpent > (SELECT AVG(TotalSpent) FROM CustomerOrders)
)
SELECT 
    p.p_partkey,
    p.p_name,
    sp.TotalAvailableQty,
    sp.UniqueSuppliers,
    c.c_name AS TopCustomer,
    co.TotalSpent AS CustomerSpending,
    RANK() OVER (ORDER BY co.TotalSpent DESC) AS SpendingRank
FROM 
    part p
LEFT JOIN 
    SupplierParts sp ON p.p_partkey = sp.ps_partkey
LEFT OUTER JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    RankedOrders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    HighValueCustomers co ON o.o_custkey = co.c_custkey
WHERE 
    (sp.TotalAvailableQty IS NULL OR sp.TotalAvailableQty > 0)
    AND (co.TotalSpent IS NOT NULL OR co.OrdersCount > 5)
    AND (p.p_retailprice BETWEEN 50 AND 100 OR p.p_name LIKE '%special%')
UNION ALL
SELECT 
    p.p_partkey,
    'Aggregate' AS p_name,
    SUM(sp.TotalAvailableQty) AS TotalAvailableQty,
    COUNT(DISTINCT sp.UniqueSuppliers) AS UniqueSuppliers,
    NULL AS TopCustomer,
    SUM(co.TotalSpent) AS CustomerSpending,
    1 AS SpendingRank
FROM 
    part p
LEFT JOIN 
    SupplierParts sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN 
    RankedOrders o ON sp.ps_partkey = o.o_orderkey
LEFT JOIN 
    HighValueCustomers co ON o.o_custkey = co.c_custkey
GROUP BY 
    p.p_partkey
HAVING 
    SUM(sp.TotalAvailableQty) IS NOT NULL
ORDER BY 
    SpendingRank, TotalAvailableQty DESC;
