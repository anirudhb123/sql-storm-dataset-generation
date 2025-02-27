WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_comment,
        CONCAT('Supplier: ', s.s_name, ', Location: ', s.s_address) AS full_info
    FROM 
        supplier s
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_type,
        p.p_brand,
        p.p_retailprice,
        LENGTH(p.p_name) AS name_length,
        REGEXP_REPLACE(p.p_comment, '[^a-zA-Z0-9]', '') AS sanitized_comment
    FROM 
        part p
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS part_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    sd.s_name,
    sd.s_address,
    pd.p_name,
    ods.total_revenue,
    ods.part_count,
    pd.sanitized_comment
FROM 
    SupplierDetails sd
JOIN 
    partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN 
    PartDetails pd ON ps.ps_partkey = pd.p_partkey
JOIN 
    OrderSummary ods ON ods.o_custkey = sd.s_suppkey
WHERE 
    pd.name_length > 10
ORDER BY 
    ods.total_revenue DESC, 
    sd.s_name;
