
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
        o.o_orderdate >= CURRENT_DATE - INTERVAL '12 months'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    s.s_name AS Supplier,
    COUNT(DISTINCT l.l_orderkey) AS OrderCount,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS Revenue,
    COALESCE(SUM(c.TotalSpent), 0) AS CustomerSpend,
    STRING_AGG(DISTINCT r.r_name, ', ') AS RegionsServed,
    AVG(sd.TotalCost) AS AverageSupplierCost
FROM 
    lineitem l
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    RankedOrders ro ON l.l_orderkey = ro.o_orderkey
LEFT JOIN 
    CustomerOrders c ON c.c_custkey = ro.o_orderkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    SupplierDetails sd ON s.s_suppkey = sd.s_suppkey
WHERE 
    l.l_returnflag = 'N'
GROUP BY 
    s.s_name
HAVING 
    SUM(l.l_extendedprice) > (SELECT AVG(l_extendedprice) FROM lineitem) 
    AND COUNT(DISTINCT l.l_orderkey) > 5
ORDER BY 
    Revenue DESC;
