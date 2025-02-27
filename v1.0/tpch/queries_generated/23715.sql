WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(month, -12, GETDATE())
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS TotalAvailQty,
        AVG(ps.ps_supplycost) AS AvgSupplyCost
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
        CUME_DIST() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(o.o_totalprice) DESC) AS SpendingDist
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    n.n_name,
    COALESCE(MAX(r.TotalSpent), 0) AS MaxSpent,
    COUNT(DISTINCT c.c_custkey) AS CustomerCount,
    COUNT(DISTINCT p.p_partkey) FILTER (WHERE sp.TotalAvailQty IS NOT NULL) AS AvailablePartsCount,
    SUM(CASE WHEN l_discount > 0.1 THEN l_extendedprice * (1 - l_discount) ELSE l_extendedprice END) AS TotalDiscExtendedPrice
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    supplierparts sp ON sp.ps_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
LEFT JOIN 
    lineitem l ON l.l_suppkey = s.s_suppkey AND l.l_returnflag = 'N'
LEFT JOIN 
    CustomerOrders r ON c.c_custkey = r.c_custkey
RIGHT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
WHERE 
    n.n_name LIKE 'A%' OR n.n_name IS NULL
GROUP BY 
    n.n_name
HAVING 
    MAX(r.TotalSpent) > 1000 AND COUNT(DISTINCT c.c_custkey) >= 10
ORDER BY 
    n.n_name IS NULL DESC, MaxSpent DESC;
