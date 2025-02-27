WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS BrandRank
    FROM 
        part p
    WHERE 
        LENGTH(p.p_comment) > 15
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        SUBSTRING(s.s_address, 1, 20) AS ShortAddress
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 5
)
SELECT 
    rp.p_name,
    rp.p_mfgr,
    rp.p_brand,
    sd.ShortAddress,
    co.c_name,
    co.OrderCount,
    co.TotalSpent
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
JOIN 
    CustomerOrders co ON co.TotalSpent > (SELECT AVG(TotalSpent) FROM CustomerOrders)
WHERE 
    rp.BrandRank <= 3
ORDER BY 
    rp.p_retailprice DESC, co.TotalSpent DESC;
