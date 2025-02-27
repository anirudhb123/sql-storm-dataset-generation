WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS BrandRank
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT p2.p_size FROM part p2 WHERE p2.p_retailprice < 50.00)
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        REPLACE(REPLACE(s.s_comment, 'supply', 'distribution'), 'available', 'local') AS ModifiedComment
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000.00
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderstatus,
        COUNT(l.l_orderkey) AS LineItemCount,
        MAX(o.o_totalprice) AS MaxOrderValue,
        MIN(o.o_orderdate) AS FirstOrderDate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderstatus
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    sd.s_name,
    sd.ModifiedComment,
    co.o_orderkey,
    co.LineItemCount,
    co.MaxOrderValue,
    co.FirstOrderDate
FROM 
    RankedParts rp
JOIN 
    SupplierDetails sd ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sd.s_suppkey)
JOIN 
    CustomerOrders co ON co.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = rp.p_partkey)
WHERE 
    rp.BrandRank <= 5
ORDER BY 
    rp.p_brand, 
    co.MaxOrderValue DESC;
