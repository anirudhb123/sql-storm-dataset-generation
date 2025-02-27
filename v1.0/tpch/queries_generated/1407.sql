WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        orders o
), SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS TotalAvailable,
        AVG(ps.ps_supplycost) AS AvgSupplyCost,
        COUNT(DISTINCT ps.ps_partkey) AS UniquePartsSupplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS TotalSpent,
        DENSE_RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS SpendingRank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 5000
)
SELECT 
    coalesce(s s_name, 'Unknown Supplier') AS SupplierName,
    p.p_name AS PartName,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS SalesRevenue,
    AVG(n.n_nationkey::decimal) AS AverageNationKey,
    COUNT(DISTINCT c.c_custkey) AS UniqueCustomers
FROM 
    lineitem l
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
LEFT JOIN 
    customer c ON c.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = l.l_orderkey)
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    l.l_shipdate > '2022-01-01' 
    AND (l.l_discount > 0.1 OR l.l_returnflag = 'R')
    AND p.p_retailprice < 100.00
GROUP BY 
    ROLLUP (s.s_name, p.p_name)
HAVING 
    SUM(l.l_extendedprice) IS NOT NULL
ORDER BY 
    SalesRevenue DESC, SupplierName, PartName;
