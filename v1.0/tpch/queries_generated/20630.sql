WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_size,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_size ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL 
        AND EXISTS (SELECT 1 FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey AND ps.ps_availqty > 0)
),
LastOrderDates AS (
    SELECT 
        o.o_custkey,
        MAX(o.o_orderdate) AS LastOrderDate
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_custkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name AS SupplierName,
    c.c_name AS CustomerName,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
    COALESCE(AVG(l.l_tax), 0) AS AvgTax,
    CASE 
        WHEN SUM(l.l_quantity) > 100 THEN 'High Volume'
        ELSE 'Regular Volume'
    END AS VolumeCategory,
    COUNT(DISTINCT l.l_orderkey) AS OrderCount,
    (SELECT COUNT(*) FROM FilteredSuppliers fs WHERE fs.s_nationkey = c.c_nationkey) AS LocalSuppliersCount
FROM 
    RankedParts p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    FilteredSuppliers s ON s.s_suppkey = l.l_suppkey
WHERE 
    c.c_acctbal BETWEEN 500 AND 2000 
    AND l.l_shipdate < (SELECT MAX(LastOrderDate) FROM LastOrderDates d WHERE d.o_custkey = c.c_custkey)
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, c.c_name
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 1
ORDER BY 
    TotalRevenue DESC, VolumeCategory DESC NULLS LAST;
