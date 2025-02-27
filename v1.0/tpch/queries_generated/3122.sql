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
        o.o_orderstatus = 'F'
        AND l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_sales,
        ss.order_count,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        supplier s
    LEFT JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    rs.s_suppkey,
    rs.s_name,
    COALESCE(rs.total_sales, 0) AS total_sales,
    COALESCE(rs.order_count, 0) AS order_count,
    rs.sales_rank
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    RankedSuppliers rs ON n.n_nationkey = (SELECT s_nationkey FROM supplier WHERE s_suppkey = rs.s_suppkey)
WHERE 
    n.n_nationkey IN (SELECT DISTINCT c.c_nationkey FROM customer c WHERE c.c_mktsegment = 'BUILDING')
ORDER BY 
    r.r_name, n.n_name, rs.sales_rank
LIMIT 100;
