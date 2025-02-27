WITH RankedSales AS (
    SELECT 
        ps.ps_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        ps.ps_partkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal 
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
NationalSales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(l.l_extendedprice) AS nation_sales
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COALESCE(hvs.s_name, 'No Supplier') AS supplier_name,
    COALESCE(hvs.s_acctbal, 0) AS supplier_acctbal,
    rs.total_sales,
    ns.nation_sales,
    CASE 
        WHEN rs.sales_rank = 1 THEN 'Top Seller'
        ELSE 'Normal Seller'
    END AS sales_status
FROM 
    part p
LEFT JOIN 
    RankedSales rs ON p.p_partkey = rs.ps_partkey
LEFT JOIN 
    HighValueSuppliers hvs ON hvs.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = p.p_partkey 
        ORDER BY ps.ps_supplycost DESC 
        LIMIT 1
    )
LEFT JOIN 
    NationalSales ns ON ns.n_nationkey = (
        SELECT n.n_nationkey 
        FROM nation n 
        JOIN supplier s ON n.n_nationkey = s.s_nationkey 
        WHERE s.s_suppkey = hvs.s_suppkey
        LIMIT 1
    )
WHERE 
    p.p_retailprice > 100
ORDER BY 
    p.p_partkey;
