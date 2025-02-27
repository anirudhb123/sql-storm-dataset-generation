WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2) 
            THEN 'High Value'
            WHEN s.s_acctbal < (SELECT AVG(s2.s_acctbal) FROM supplier s2) 
            THEN 'Low Value'
            ELSE 'Average Value'
        END AS Value_Category
    FROM 
        supplier s
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '1997-01-01'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    r.r_name AS region_name,
    os.total_sales,
    os.unique_parts,
    si.Value_Category
FROM 
    RankedParts p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    OrderSummary os ON os.o_orderkey = (
        SELECT 
            o.o_orderkey 
        FROM 
            orders o 
        JOIN 
            lineitem l ON o.o_orderkey = l.l_orderkey 
        WHERE 
            l.l_partkey = p.p_partkey 
        ORDER BY 
            o.o_orderdate DESC 
        LIMIT 1
    )
JOIN 
    SupplierInfo si ON s.s_suppkey = si.s_suppkey
WHERE 
    p.p_retailprice BETWEEN 100.00 AND 500.00 
    AND p.p_partkey NOT IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty < 10)
    AND s.s_acctbal IS NOT NULL
ORDER BY 
    p.p_brand, p.p_retailprice ASC;