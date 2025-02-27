WITH RECURSIVE order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name AS customer_name,
        s.s_name AS supplier_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, s.s_name
),
region_sales AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(os.total_sales) AS total_region_sales
    FROM 
        order_summary os
    JOIN 
        customer c ON os.customer_name = c.c_name
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        r.r_name
)
SELECT 
    region_name,
    order_count,
    total_region_sales,
    RANK() OVER (ORDER BY total_region_sales DESC) AS sales_rank
FROM 
    region_sales
WHERE 
    order_count > 10
ORDER BY 
    total_region_sales DESC;
