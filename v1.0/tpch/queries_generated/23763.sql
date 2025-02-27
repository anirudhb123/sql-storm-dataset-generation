WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), 
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        c.c_custkey,
        c.c_name,
        c.c_acctbal
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderdate = o.o_orderdate)
), 
SupplierPartCounts AS (
    SELECT 
        p.p_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS DefaultSupplierCount
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    COALESCE(rs.s_name, 'No Supplier') AS SupplierName,
    f.o_orderkey,
    f.o_totalprice,
    CASE 
        WHEN rs.SupplierRank IS NOT NULL AND rs.SupplierRank = 1 THEN 'Top Supplier'
        ELSE 'Regular'
    END AS SupplierType,
    CASE 
        WHEN f.c_acctbal IS NULL THEN 'Unknown Bal'
        ELSE f.c_acctbal::TEXT
    END AS CustomerBalance,
    sp.DefaultSupplierCount
FROM 
    part p
LEFT JOIN 
    RankedSuppliers rs ON rs.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey AND rs.SupplierRank = 1)
LEFT JOIN 
    FilteredOrders f ON f.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = f.c_custkey ORDER BY o.o_orderdate DESC LIMIT 1)
LEFT JOIN 
    SupplierPartCounts sp ON sp.p_partkey = p.p_partkey
WHERE 
    p.p_retailprice > (
        SELECT MAX(p2.p_retailprice) * 0.75 FROM part p2 
        WHERE p2.p_size BETWEEN 1 AND 100
    )
ORDER BY 
    p.p_partkey, 
    f.o_orderdate DESC,
    p.p_name;
