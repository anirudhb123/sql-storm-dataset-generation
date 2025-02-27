WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        ROW_NUMBER() OVER(PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(YEAR, -1, GETDATE()) 
        AND o.o_orderstatus IN ('O', 'F')
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS TotalAvailable,
        COUNT(DISTINCT ps.ps_suppkey) AS UniqueSuppliers
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(sp.TotalAvailable, 0) AS TotalAvailable
    FROM 
        part p
    LEFT JOIN 
        SupplierParts sp ON p.p_partkey = sp.ps_partkey
    WHERE 
        p.p_retailprice > 100 
        OR (p.p_size BETWEEN 10 AND 20 AND TotalAvailable > 0)
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) IS NOT NULL 
        AND SUM(o.o_totalprice) > 1000
)
SELECT 
    fp.p_partkey,
    fp.p_name,
    fp.p_retailprice,
    co.c_custkey,
    co.c_name,
    co.TotalSpent,
    o.OrderRank
FROM 
    FilteredParts fp
LEFT JOIN 
    CustomerOrders co ON fp.TotalAvailable > 0
LEFT JOIN 
    RankedOrders o ON o.o_orderkey IN (
        SELECT o2.o_orderkey
        FROM orders o2
        JOIN lineitem l ON o2.o_orderkey = l.l_orderkey
        WHERE l.l_partkey = fp.p_partkey
    )
WHERE 
    fp.TotalAvailable IS NOT NULL
    AND (co.TotalSpent IS NULL OR co.TotalSpent < 5000)
ORDER BY 
    fp.p_retailprice DESC, co.TotalSpent ASC 
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;
