WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        CONCAT(p.p_name, ' ', p.p_type) AS full_description,
        COALESCE(NULLIF(p.p_comment, '') , 'No Comments') AS sanitized_comment
    FROM 
        part p
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        CASE 
            WHEN LENGTH(s.s_address) > 30 THEN CONCAT(SUBSTRING(s.s_address, 1, 27), '...')
            ELSE s.s_address 
        END AS short_address,
        REPLACE(s.s_comment, 'supply', 'supplying') AS modified_comment
    FROM 
        supplier s
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderstatus,
        STRING_AGG(CONCAT('Item:', l.l_linenumber, ' Price:', l.l_extendedprice), '; ') AS order_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderstatus
)
SELECT 
    pd.full_description,
    sd.short_address,
    co.o_orderkey,
    co.order_items,
    COUNT(*) OVER (PARTITION BY pd.p_partkey) AS part_count,
    SUM(p.p_retailprice) OVER (PARTITION BY sd.s_nationkey) AS total_retail_price_per_nation,
    CONCAT('Processed by ', s.s_name, ' with order status ', co.o_orderstatus) AS processing_info
FROM 
    PartDetails pd
JOIN 
    SupplierDetails sd ON pd.p_partkey = sd.s_nationkey 
JOIN 
    CustomerOrders co ON sd.s_nationkey = co.o_custkey
WHERE 
    pd.sanitized_comment LIKE '%quality%'
    AND sd.modified_comment LIKE '%delivery%'
ORDER BY 
    pd.p_partkey, co.o_orderkey;
