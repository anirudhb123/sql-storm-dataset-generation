WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(SUM(l.l_quantity), 0) AS total_quantity_sold,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_sales
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
),
HighValueParts AS (
    SELECT 
        pd.*,
        CASE 
            WHEN pd.total_sales > 10000 THEN 'High Value'
            ELSE 'Regular'
        END AS value_category
    FROM 
        PartDetails pd
    WHERE 
        pd.total_quantity_sold > 5
)
SELECT 
    DISTINCT 
    r.r_name AS region_name,
    np.n_name AS nation_name,
    p.p_name AS part_name,
    p.value_category,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(s.s_acctbal) AS avg_supplier_acctbal,
    MAX(s.s_acctbal) AS max_supplier_acctbal,
    SUM(pd.total_sales) AS total_sales_value
FROM 
    HighValueParts p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation np ON s.s_nationkey = np.n_nationkey
JOIN 
    region r ON np.n_regionkey = r.r_regionkey
LEFT JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
WHERE 
    rs.SupplierRank = 1
AND 
    p.value_category = 'High Value'
GROUP BY 
    r.r_name, np.n_name, p.p_name, p.value_category
ORDER BY 
    total_sales_value DESC
LIMIT 10;
