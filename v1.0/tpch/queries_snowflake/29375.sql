
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        LENGTH(p.p_name) AS name_length,
        SUBSTRING(p.p_comment, 1, 10) AS short_comment,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY LENGTH(p.p_name) DESC) AS rank_within_brand
    FROM 
        part p
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        REPLACE(s.s_address, 'Street', 'St.') AS modified_address,
        CONCAT('Supplier: ', s.s_name, ' located at ', REPLACE(s.s_address, 'Street', 'St.')) AS full_description
    FROM 
        supplier s
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderstatus,
        CONCAT(c.c_name, ' with customer key ', c.c_custkey, ' has ordered with status ', o.o_orderstatus) AS order_summary
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.name_length,
    rp.short_comment,
    sd.full_description,
    co.order_summary
FROM 
    RankedParts rp
JOIN 
    SupplierDetails sd ON sd.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'UNITED STATES' LIMIT 1)
JOIN 
    CustomerOrders co ON co.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = rp.p_partkey)
WHERE 
    rp.rank_within_brand = 1
ORDER BY 
    rp.name_length DESC, 
    sd.full_description;
