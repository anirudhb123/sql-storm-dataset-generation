
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100.00
),
CustomerSuppliers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        s.s_name AS supplier_name,
        ps.ps_supplycost,
        ps.ps_partkey
    FROM 
        customer c
    JOIN 
        supplier s ON c.c_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    rp.p_type,
    rp.p_retailprice,
    cs.c_name,
    COUNT(cs.c_custkey) AS customer_count,
    SUM(cs.ps_supplycost) AS total_supply_cost
FROM 
    RankedParts rp
JOIN 
    CustomerSuppliers cs ON rp.p_partkey = cs.ps_partkey
WHERE 
    rp.rank <= 5
GROUP BY 
    rp.p_partkey, rp.p_name, rp.p_brand, rp.p_type, rp.p_retailprice, cs.c_name
ORDER BY 
    rp.p_retailprice DESC, customer_count DESC;
