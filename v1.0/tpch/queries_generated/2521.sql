WITH TotalSales AS (
    SELECT 
        l_partkey,
        SUM(l_extendedprice * (1 - l_discount)) AS sales
    FROM 
        lineitem
    WHERE 
        l_shipdate >= DATE '2023-01-01' AND 
        l_shipdate < DATE '2024-01-01'
    GROUP BY 
        l_partkey
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name, r.r_name
), 
RankedSales AS (
    SELECT 
        ts.l_partkey,
        ts.sales,
        RANK() OVER (ORDER BY ts.sales DESC) AS sales_rank
    FROM 
        TotalSales ts
),
HighValueSuppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        sd.part_count
    FROM 
        SupplierDetails sd
    WHERE 
        sd.s_acctbal > (SELECT 
                             AVG(s_acctbal) 
                         FROM 
                             supplier) 
    AND 
        sd.part_count > 5
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(r.sales_rank, 0) AS sales_rank,
    COALESCE(s.s_name, 'N/A') AS supplier_name
FROM 
    part p
LEFT JOIN 
    RankedSales r ON p.p_partkey = r.l_partkey
LEFT JOIN 
    HighValueSuppliers s ON s.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = p.p_partkey
        ORDER BY ps.ps_supplycost ASC 
        LIMIT 1
    )
WHERE 
    r.sales > 10000 OR s.part_count IS NOT NULL
ORDER BY 
    r.sales_rank, p.p_partkey;
