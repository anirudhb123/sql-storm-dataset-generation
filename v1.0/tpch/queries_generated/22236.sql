WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),
TotalSales AS (
    SELECT 
        li.l_partkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales
    FROM 
        lineitem li
    WHERE 
        li.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY 
        li.l_partkey
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        COALESCE(ps.ps_availqty, 0) AS available_quantity,
        COALESCE(ts.total_sales, 0) AS sales_value
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        TotalSales ts ON p.p_partkey = ts.l_partkey
    WHERE 
        p.p_retailprice < (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size > 20)
)
SELECT 
    fp.p_partkey,
    fp.p_name,
    COUNT(rs.s_suppkey) AS supplier_count,
    SUM(fp.available_quantity) AS total_available,
    SUM(fp.sales_value) AS total_sales,
    MAX(fp.sales_value) OVER (PARTITION BY fp.p_brand) AS max_sales_per_brand
FROM 
    FilteredParts fp
LEFT JOIN 
    RankedSuppliers rs ON fp.available_quantity > 0 AND fp.p_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_availqty > 100
    )
GROUP BY 
    fp.p_partkey, fp.p_name
HAVING 
    SUM(fp.sales_value) > 0 OR MAX(fp.sales_value) IS NULL
ORDER BY 
    supplier_count DESC, total_sales DESC;
