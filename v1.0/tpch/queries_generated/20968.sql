WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY ps.partkey ORDER BY ps.ps_supplycost DESC) AS supply_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
FilteredSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.supply_rank <= 3  -- Top 3 suppliers based on supply cost
),
AggregatedSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N' 
        AND l.l_shipdate BETWEEN '2023-01-01' AND '2023-10-31'
    GROUP BY 
        l.l_partkey
),
RareParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        COALESCE(av.total_sales, 0) AS total_sales
    FROM 
        part p
    LEFT JOIN 
        AggregatedSales av ON p.p_partkey = av.l_partkey
    WHERE 
        p.p_size IS NOT NULL
        AND p.p_retailprice < (
            SELECT AVG(p2.p_retailprice) * 0.75
            FROM part p2
            WHERE p2.p_brand = p.p_brand
        ) 
),
FinalResults AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        COUNT(DISTINCT fs.s_suppkey) AS supplier_count,
        rp.total_sales
    FROM 
        RareParts rp
    LEFT JOIN 
        FilteredSuppliers fs ON EXISTS (
            SELECT 1 FROM partsupp ps 
            WHERE ps.ps_partkey = rp.p_partkey AND ps.ps_suppkey = fs.s_suppkey
        )
    GROUP BY 
        rp.p_partkey,
        rp.p_name,
        rp.total_sales
    HAVING 
        COUNT(DISTINCT fs.s_suppkey) > 0
)
SELECT 
    fr.p_partkey,
    fr.p_name,
    fr.supplier_count,
    fr.total_sales,
    CASE 
        WHEN fr.total_sales >= 10000 THEN 'High Seller'
        WHEN fr.total_sales >= 5000 THEN 'Medium Seller'
        ELSE 'Low Seller'
    END AS sales_category
FROM 
    FinalResults fr
WHERE 
    fr.total_sales IS NOT NULL
    AND (fr.total_sales BETWEEN 500 AND 15000 OR fr.supplier_count > 2)
ORDER BY 
    fr.total_sales DESC,
    fr.supplier_count ASC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;


