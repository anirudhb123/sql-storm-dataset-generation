
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ps.ps_availqty,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice, ps.ps_availqty
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
PartSupplier AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(h.total_sales, 0) AS total_sales,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    ps.supplier_count,
    p.p_retailprice,
    CASE 
        WHEN p.p_retailprice IS NULL THEN 'Price Not Available'
        WHEN p.p_retailprice < 50 THEN 'Low Price'
        WHEN p.p_retailprice BETWEEN 50 AND 100 THEN 'Medium Price'
        ELSE 'High Price'
    END AS price_category
FROM 
    part p
LEFT JOIN 
    HighValueParts h ON p.p_partkey = h.p_partkey
LEFT JOIN 
    RankedSuppliers s ON s.rank = 1 AND s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey)
JOIN 
    PartSupplier ps ON p.p_partkey = ps.ps_partkey
WHERE 
    p.p_size IS NOT NULL AND p.p_container NOT LIKE '%invalid%'
ORDER BY 
    total_sales DESC, p.p_name;
