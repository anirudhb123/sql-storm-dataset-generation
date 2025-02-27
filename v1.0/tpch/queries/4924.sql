WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
FilteredSuppliers AS (
    SELECT
        ss.s_suppkey,
        ss.s_name,
        ss.total_revenue
    FROM 
        SupplierSales ss
    WHERE 
        ss.total_revenue > (SELECT AVG(total_revenue) FROM SupplierSales)
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    COALESCE(fs.total_revenue, 0) AS supplier_revenue,
    CASE 
        WHEN fs.total_revenue IS NOT NULL THEN 'Above Average'
        ELSE 'Below Average'
    END AS revenue_category
FROM 
    part p
LEFT JOIN 
    FilteredSuppliers fs ON fs.s_suppkey = (
        SELECT 
            ps.ps_suppkey 
        FROM 
            partsupp ps 
        WHERE 
            ps.ps_partkey = p.p_partkey
        ORDER BY 
            ps.ps_availqty DESC
        LIMIT 1
    )
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
ORDER BY 
    p.p_partkey;
