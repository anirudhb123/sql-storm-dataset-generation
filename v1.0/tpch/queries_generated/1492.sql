WITH SupplierSales AS (
    SELECT 
        s.s_name,
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_name, n.n_name
),
RankedSales AS (
    SELECT 
        s_name, 
        nation_name, 
        total_sales,
        order_count,
        RANK() OVER (PARTITION BY nation_name ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SupplierSales
),
FilteredSales AS (
    SELECT 
        s_name, 
        nation_name, 
        total_sales, 
        order_count
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
)
SELECT 
    f.nation_name,
    STRING_AGG(f.s_name, ', ') AS suppliers,
    SUM(f.total_sales) AS total_nation_sales,
    AVG(f.order_count) AS average_orders_per_supplier
FROM 
    FilteredSales f
GROUP BY 
    f.nation_name
ORDER BY 
    total_nation_sales DESC
WITH ROLLUP;
