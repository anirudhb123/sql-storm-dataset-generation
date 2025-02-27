WITH ProcessedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        CONCAT('Manufacturer: ', TRIM(p.p_mfgr), ' | Type: ', UPPER(p.p_type), ' | Size: ', p.p_size) AS processed_info
    FROM 
        part p
    WHERE 
        p.p_retailprice > 20.00
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        CONCAT(SUBSTRING(s.s_address, 1, 20), '...') AS short_address
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000.00
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_quantity) AS total_quantity,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_totalprice
)
SELECT 
    pp.processed_info,
    si.s_name,
    si.short_address,
    os.o_totalprice,
    os.total_quantity,
    os.unique_parts
FROM 
    ProcessedParts pp
JOIN 
    SupplierInfo si ON pp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost < pp.p_partkey * 1.5)
JOIN 
    OrderSummary os ON os.unique_parts > 5
ORDER BY 
    os.o_totalprice DESC
LIMIT 100;
