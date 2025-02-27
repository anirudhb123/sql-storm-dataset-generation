WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o 
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' 
        AND o.o_orderstatus IN ('O', 'F')
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) as order_count
    FROM 
        supplier s 
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        s.s_acctbal IS NOT NULL 
        AND l.l_discount BETWEEN 0.05 AND 0.10
    GROUP BY 
        s.s_suppkey
),
FilteredSuppliers AS (
    SELECT 
        s.s_name,
        s.s_acctbal
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s1.s_acctbal) FROM supplier s1)
),
DistinctRegions AS (
    SELECT DISTINCT 
        n.n_regionkey,
        r.r_name 
    FROM 
        nation n 
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        n.n_comment NOT LIKE '%forest%'
),
FinalReport AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        COALESCE(s.total_sales, 0) AS supplier_sales,
        COALESCE(s.order_count, 0) AS total_orders,
        r.r_name AS region_name
    FROM 
        RankedOrders o 
    LEFT JOIN 
        SupplierSales s ON o.o_orderkey = s.s_suppkey
    LEFT JOIN 
        FilteredSuppliers fs ON s.s_suppkey = fs.s_suppkey
    LEFT JOIN 
        DistinctRegions r ON o.o_orderkey % 5 = r.n_regionkey
    WHERE 
        o.o_totalprice > 10000 
        AND (s.total_sales IS NULL OR s.total_sales < 1000) 
        OR (s.total_sales IS NOT NULL AND s.total_sales >= 1000)
)
SELECT 
    * 
FROM 
    FinalReport
WHERE 
    (region_name IS NOT NULL OR supplier_sales > 500)
ORDER BY 
    o_orderdate DESC, 
    total_orders DESC NULLS LAST;
