
WITH RecursiveSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
), CTE_PartInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank,
        CASE 
            WHEN p.p_size IS NULL THEN 'unknown_size'
            ELSE CAST(p.p_size AS VARCHAR)
        END AS size_info
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100.00
), NationalSupplier AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    ns.n_name,
    ns.supplier_count,
    COALESCE(rs.total_sales, 0) AS total_customer_sales,
    pi.p_name,
    pi.p_retailprice,
    pi.size_info
FROM 
    NationalSupplier ns
LEFT JOIN 
    RecursiveSales rs ON ns.supplier_count = rs.sales_rank
LEFT JOIN 
    CTE_PartInfo pi ON rs.total_sales = (
        SELECT MAX(r.total_sales) FROM RecursiveSales r WHERE r.c_custkey = rs.c_custkey
    ) 
WHERE 
    ns.supplier_count > 5
ORDER BY 
    ns.n_name, total_customer_sales DESC
LIMIT 10;
