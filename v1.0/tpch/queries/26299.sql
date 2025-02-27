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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) as rn
    FROM 
        part p
    WHERE 
        LENGTH(p.p_comment) > 5
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        s.s_phone, 
        s.s_acctbal,
        s.s_comment
    FROM 
        supplier s
    WHERE 
        (s.s_comment LIKE '%reliable%' OR s.s_comment LIKE '%quality%')
        AND s.s_acctbal > 1000
), 
CombinedData AS (
    SELECT 
        rp.p_name, 
        rp.p_retailprice, 
        fs.s_name, 
        fs.s_address
    FROM 
        RankedParts rp
    JOIN 
        partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN 
        FilteredSuppliers fs ON ps.ps_suppkey = fs.s_suppkey
    WHERE 
        rp.rn <= 5
)
SELECT 
    COUNT(*) AS Total_Entries, 
    AVG(p_retailprice) AS Average_Retail_Price, 
    STRING_AGG(CONCAT_WS(' - ', p_name, s_name, s_address), '; ') AS Part_Supplier_Info
FROM 
    CombinedData;
