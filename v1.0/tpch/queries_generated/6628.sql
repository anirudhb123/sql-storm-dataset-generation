WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(o.o_totalprice) AS total_sales
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        r.r_name
), ProductSales AS (
    SELECT 
        p.p_name AS product_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS product_sales
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        p.p_name
), TopProducts AS (
    SELECT 
        product_name,
        product_sales,
        RANK() OVER (ORDER BY product_sales DESC) AS sales_rank
    FROM 
        ProductSales
)
SELECT 
    rs.region_name,
    tp.product_name,
    tp.product_sales,
    tp.sales_rank
FROM 
    RegionalSales rs
JOIN 
    lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01')
JOIN 
    TopProducts tp ON l.l_partkey IN (SELECT p.p_partkey FROM part p)
ORDER BY 
    rs.region_name, tp.sales_rank;
