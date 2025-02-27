WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        s.s_phone, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS SupplierRank
    FROM 
        supplier s
),
HighValueItems AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        p.p_comment,
        COUNT(DISTINCT ps.ps_suppkey) AS SupplierCount
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    GROUP BY 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_retailprice, 
        p.p_comment
)
SELECT 
    r.r_name AS Region, 
    n.n_name AS Nation, 
    s.s_name AS Supplier, 
    i.p_name AS ItemName, 
    i.p_brand AS ItemBrand, 
    i.p_retailprice AS RetailPrice, 
    i.SupplierCount
FROM 
    RankedSuppliers s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    HighValueItems i ON s.s_suppkey = i.p_partkey
WHERE 
    s.SupplierRank <= 5
ORDER BY 
    r.r_name, n.n_name, s.s_name;
