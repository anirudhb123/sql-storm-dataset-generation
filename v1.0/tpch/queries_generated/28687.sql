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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100.00
),
SelectedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey
    FROM 
        supplier s
    WHERE 
        EXISTS (
            SELECT 
                1 
            FROM 
                partsupp ps 
            WHERE 
                ps.ps_suppkey = s.s_suppkey 
                AND ps.ps_availqty > 50
        )
),
PartSupplierDetails AS (
    SELECT 
        rp.p_partkey, 
        rp.p_name, 
        rp.p_brand,
        ss.s_suppkey,
        ss.s_name,
        ss.s_nationkey
    FROM 
        RankedParts rp
    JOIN 
        partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN 
        SelectedSuppliers ss ON ps.ps_suppkey = ss.s_suppkey
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_brand,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(p.p_retailprice) AS average_price
FROM 
    PartSupplierDetails p
JOIN 
    part ps ON p.p_partkey = ps.p_partkey
GROUP BY 
    p.p_partkey, 
    p.p_name, 
    p.p_brand
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 2
ORDER BY 
    average_price DESC;
