WITH RankedSuppliers AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) as SupplierRank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS TotalSpent,
        COUNT(o.o_orderkey) AS OrderCount
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
QualifiedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_retailprice,
        COALESCE(SUM(l.l_quantity), 0) AS TotalQuantity
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey AND l.l_returnflag = 'N'
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_retailprice
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    p.p_retailprice,
    COALESCE(r.TotalQuantity, 0) AS TotalQuantity,
    s.s_name AS BestSupplier,
    c.TotalSpent AS CustomerTotalSpent
FROM 
    QualifiedParts p
LEFT JOIN 
    RankedSuppliers r ON p.p_partkey = r.ps_partkey AND r.SupplierRank = 1
LEFT JOIN 
    CustomerOrders c ON c.c_custkey IN (SELECT DISTINCT o.o_custkey FROM orders o WHERE o.o_orderdate >= '2023-01-01')
ORDER BY 
    p.p_retailprice DESC, TotalQuantity DESC
LIMIT 100
OFFSET 0;
