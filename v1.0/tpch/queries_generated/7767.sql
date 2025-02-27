WITH PartSupplierSales AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        r.r_name = 'Europe'
    GROUP BY 
        p.p_partkey
),
RankedSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.ps_availqty,
        ps.ps_supplycost,
        ps.ps_comment,
        ps.ps_partkey,
        COALESCE(p.total_sales, 0) AS total_sales,
        COALESCE(p.order_count, 0) AS order_count,
        RANK() OVER (ORDER BY COALESCE(p.total_sales, 0) DESC, p.p_partkey) AS sales_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        PartSupplierSales p ON p.p_partkey = p.p_partkey
)
SELECT 
    r.r_name AS region_name,
    rs.p_partkey,
    rs.p_name,
    rs.p_mfgr,
    rs.p_type,
    rs.p_size,
    rs.p_retailprice,
    rs.ps_supplycost,
    rs.total_sales,
    rs.order_count,
    rs.sales_rank
FROM 
    RankedSales rs
JOIN 
    supplier s ON rs.ps_partkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    rs.sales_rank <= 10
ORDER BY 
    rs.sales_rank;
