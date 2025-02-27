WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type, 
        p.p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS PriceRank
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size IS NOT NULL)
), 

HighVolumeSuppliers AS (
    SELECT 
        ps.ps_suppkey, 
        SUM(ps.ps_availqty) AS TotalAvailable
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
    HAVING 
        SUM(ps.ps_availqty) > 1000
), 

SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        COALESCE(n.n_name, 'UNKNOWN') AS nation_name
    FROM 
        supplier s
    LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
), 

CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)

SELECT 
    COALESCE(sd.nation_name, 'UNSPECIFIED') AS SupplierNation,
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    hv.TotalAvailable,
    co.OrderCount,
    co.TotalSpent,
    CASE 
        WHEN co.TotalSpent / NULLIF(co.OrderCount, 0) > 1000 THEN 'High Value Customer'
        ELSE 'Regular Customer' 
    END AS CustomerType
FROM 
    RankedParts rp
JOIN 
    HighVolumeSuppliers hv ON rp.p_partkey = hv.ps_partkey
JOIN 
    SupplierDetails sd ON hv.ps_suppkey = sd.s_suppkey
LEFT JOIN 
    CustomerOrders co ON sd.s_nationkey = co.c_custkey
WHERE 
    rp.PriceRank <= 10 
    AND (sd.nation_name IS NOT NULL OR sd.s_name LIKE '%Inc%')
ORDER BY 
    rp.p_retailprice DESC, 
    co.TotalSpent ASC NULLS LAST;

