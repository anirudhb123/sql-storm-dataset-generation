WITH SupplierStats AS (
    SELECT 
        s.n_nationkey,
        AVG(s.s_acctbal) AS avg_acctbal,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.n_nationkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        DENSE_RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.avg_acctbal,
    ps.total_sales,
    COALESCE(CASE 
        WHEN ps.sales_rank <= 10 THEN 'Top Seller'
        ELSE 'Other'
    END, 'Unknown') AS sales_category
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplierStats s ON n.n_nationkey = s.n_nationkey
LEFT JOIN 
    PartDetails ps ON n.n_nationkey = ps.p_partkey
WHERE 
    s.avg_acctbal IS NOT NULL AND 
    (n.n_name LIKE 'A%' OR n.n_name IS NULL)
ORDER BY 
    r.r_name, n.n_name;
