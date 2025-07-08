
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
TotalLineItemSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    GROUP BY 
        l.l_partkey
),
PartSupplierCount AS (
    SELECT 
        ps.ps_partkey,
        COUNT(*) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(ts.total_sales, 0) AS total_sales,
    COALESCE(pcs.supplier_count, 0) AS supplier_count,
    rs.s_name AS top_supplier_name
FROM 
    part p
LEFT JOIN 
    TotalLineItemSales ts ON p.p_partkey = ts.l_partkey
LEFT JOIN 
    PartSupplierCount pcs ON p.p_partkey = pcs.ps_partkey
LEFT JOIN 
    RankedSuppliers rs ON rs.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = p.p_partkey 
        ORDER BY ps.ps_supplycost ASC
        LIMIT 1
    ) AND rs.rank = 1
WHERE 
    (p.p_retailprice > 100 OR ts.total_sales IS NULL) 
    AND (COALESCE(pcs.supplier_count, 0) < 5 OR pcs.supplier_count IS NULL)
ORDER BY 
    total_sales DESC, p.p_name;
