WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        REPLACE(UPPER(p.p_comment), ' ', '-') AS formatted_comment
    FROM 
        part p
    WHERE 
        LENGTH(p.p_comment) > 10
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        SUBSTRING(s.s_comment FROM 1 FOR 50) AS short_comment
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        CONCAT(c.c_address, ', Nation Key: ', c.c_nationkey) AS full_address,
        LEFT(c.c_comment, 60) AS truncated_comment
    FROM 
        customer c
    WHERE 
        c.c_mktsegment = 'BUILDING'
)
SELECT 
    pd.p_name,
    pd.formatted_comment,
    sd.s_name,
    sd.short_comment,
    cd.c_name,
    cd.full_address,
    cd.truncated_comment
FROM 
    PartDetails pd
JOIN 
    partsupp ps ON pd.p_partkey = ps.ps_partkey
JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
JOIN 
    CustomerDetails cd ON sd.s_suppkey IN (
        SELECT 
            o.o_orderkey 
        FROM 
            orders o 
        WHERE 
            o.o_orderstatus = 'O'
    )
WHERE 
    pd.p_size BETWEEN 1 AND 50
ORDER BY 
    pd.p_name, sd.s_name, cd.c_name;
