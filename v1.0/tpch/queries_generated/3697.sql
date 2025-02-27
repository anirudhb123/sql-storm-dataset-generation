WITH RankedSales AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
    GROUP BY 
        p.p_partkey, 
        p.p_name
), SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s2.s_acctbal)
            FROM supplier s2 
            WHERE s2.s_nationkey = s.s_nationkey
        )
), CustomerCounts AS (
    SELECT 
        c.c_nationkey, 
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        customer c
    GROUP BY 
        c.c_nationkey
)

SELECT 
    n.n_name AS nation_name,
    COALESCE(SUM(r.total_sales), 0) AS total_sales,
    cc.customer_count,
    COUNT(DISTINCT sd.s_suppkey) AS supplier_count,
    CASE 
        WHEN SUM(r.total_sales) IS NULL THEN 'No Sales' 
        WHEN SUM(r.total_sales) > 100000 THEN 'High Sales' 
        ELSE 'Normal Sales' 
    END AS sales_category
FROM 
    nation n
LEFT JOIN 
    RankedSales r ON r.p_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_supplycost = (
            SELECT MIN(ps2.ps_supplycost) 
            FROM partsupp ps2 
            WHERE ps2.ps_partkey = r.p_partkey
        )
    )
LEFT JOIN 
    SupplierDetails sd ON sd.s_nationkey = n.n_nationkey
LEFT JOIN 
    CustomerCounts cc ON cc.c_nationkey = n.n_nationkey
WHERE 
    n.n_nationkey IS NOT NULL
GROUP BY 
    n.n_name, 
    cc.customer_count
ORDER BY 
    total_sales DESC NULLS LAST;
