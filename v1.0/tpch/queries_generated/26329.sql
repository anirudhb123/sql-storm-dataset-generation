WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        LENGTH(p.p_name) AS name_length,
        REGEXP_REPLACE(p.p_comment, '[^A-Za-z0-9 ]', '') AS sanitized_comment
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100.00
),
CustomerInfo AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        CONCAT(c.c_address, ' - ', c.c_phone) AS contact_info
    FROM 
        customer c
    WHERE 
        c.c_acctbal > 500.00
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(l.l_orderkey) AS items_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        o.o_orderkey
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        STRING_AGG(DISTINCT CONCAT('Part: ', p.p_name, ' | Brand: ', p.p_brand), ', ') AS supplied_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.name_length,
    ci.contact_info,
    os.total_sales,
    sp.supplied_parts
FROM 
    RankedParts rp
JOIN 
    CustomerInfo ci ON ci.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey IN (SELECT os.o_orderkey FROM OrderSummary os))
JOIN 
    OrderSummary os ON os.total_sales > 1000.00
JOIN 
    SupplierParts sp ON sp.supplied_parts LIKE CONCAT('%', rp.p_name, '%')
ORDER BY 
    rp.name_length DESC, os.total_sales DESC;
