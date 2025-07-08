
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_by_price
    FROM 
        part p
    WHERE 
        p.p_retailprice > (
            SELECT AVG(p2.p_retailprice) FROM part p2
        )
),
PartSuppliers AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.p_retailprice,
        s.s_name AS supplier_name,
        COUNT(DISTINCT ps.ps_suppkey) AS num_suppliers
    FROM 
        RankedParts rp
    JOIN 
        partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        rp.rank_by_price <= 5
    GROUP BY 
        rp.p_partkey, rp.p_name, rp.p_brand, rp.p_retailprice, s.s_name
)
SELECT 
    p.part_name,
    LISTAGG(DISTINCT ps.supplier_name, ', ') WITHIN GROUP (ORDER BY ps.supplier_name) AS suppliers_list,
    COUNT(DISTINCT ps.supplier_name) AS total_suppliers,
    MAX(p.p_retailprice) AS highest_price
FROM 
    PartSuppliers ps
JOIN 
    (SELECT 
        p_partkey AS part_key,
        p_name AS part_name,
        p_retailprice 
    FROM RankedParts) p ON ps.p_partkey = p.part_key
GROUP BY 
    p.part_name, p.p_retailprice
ORDER BY 
    total_suppliers DESC;
