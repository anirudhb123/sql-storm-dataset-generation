WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
), 
CustomerPurchases AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalPurchase
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
TopCustomers AS (
    SELECT 
        cp.c_custkey,
        cp.c_name,
        cp.TotalPurchase,
        RANK() OVER (ORDER BY cp.TotalPurchase DESC) AS PurchaseRank
    FROM 
        CustomerPurchases cp
)
SELECT 
    c.c_name, 
    c.c_address,
    r.r_name AS RegionName,
    SUM(pp.ps_supplycost * pp.ps_availqty) AS TotalSupplyCost,
    COUNT(DISTINCT o.o_orderkey) AS OrderCount
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp pp ON s.s_suppkey = pp.ps_suppkey
LEFT JOIN 
    CustomerPurchases cp ON cp.c_custkey = s.s_suppkey
LEFT JOIN 
    RankedOrders o ON o.o_orderkey = pp.ps_partkey
WHERE 
    (cp.TotalPurchase IS NULL OR cp.TotalPurchase > 10000)
    AND r.r_name IN ('ASIA', 'EUROPE')
GROUP BY 
    c.c_name, c.c_address, r.r_name
HAVING 
    SUM(pp.ps_supplycost * pp.ps_availqty) > 50000
ORDER BY 
    TotalSupplyCost DESC;
