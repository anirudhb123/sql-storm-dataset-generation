WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        s.s_suppkey, s.s_name
), 
RegionSales AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        SUM(ss.total_sales) AS region_total_sales,
        COUNT(DISTINCT ss.s_suppkey) AS supplier_count
    FROM 
        SupplierSales ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_regionkey, r.r_name
),
RankedSales AS (
    SELECT 
        r.r_name,
        r.region_total_sales,
        RANK() OVER (ORDER BY r.region_total_sales DESC) AS sales_rank
    FROM 
        RegionSales r
),
TopRegions AS (
    SELECT 
        r.r_name,
        r.region_total_sales
    FROM 
        RankedSales r
    WHERE 
        r.sales_rank <= 5
)

SELECT 
    tr.r_name,
    tr.region_total_sales,
    COALESCE(NULLIF(tr.region_total_sales, 0), 'No sales recorded') AS sales_comment,
    (SELECT COUNT(DISTINCT s.s_suppkey) 
     FROM supplier s 
     JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey 
     JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
     WHERE l.l_returnflag = 'R' AND l.l_discount > 0) AS total_returning_suppliers
FROM 
    TopRegions tr
LEFT JOIN 
    region r ON tr.r_name = r.r_name;
