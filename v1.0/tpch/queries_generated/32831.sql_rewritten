WITH RECURSIVE monthly_sales AS (
    SELECT 
        EXTRACT(YEAR FROM o_orderdate) AS order_year,
        EXTRACT(MONTH FROM o_orderdate) AS order_month,
        SUM(l_extendedprice * (1 - l_discount)) AS total_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
    GROUP BY 
        EXTRACT(YEAR FROM o_orderdate), 
        EXTRACT(MONTH FROM o_orderdate)
    
    UNION ALL
    
    SELECT 
        order_year,
        order_month + 1,
        total_sales
    FROM 
        monthly_sales
    WHERE 
        order_month < 12
),

supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS parts_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),

region_sales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(ms.total_sales) AS total_region_sales
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        monthly_sales ms ON EXTRACT(YEAR FROM o.o_orderdate) = ms.order_year AND 
                            EXTRACT(MONTH FROM o.o_orderdate) = ms.order_month
    GROUP BY 
        r.r_name
)

SELECT 
    rs.region_name,
    COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
    rs.total_region_sales,
    CASE 
        WHEN rs.total_region_sales > 1000000 THEN 'High Sales'
        WHEN rs.total_region_sales BETWEEN 500000 AND 1000000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    region_sales rs
LEFT JOIN 
    supplier_summary ss ON rs.region_name = (
        SELECT r_name 
        FROM region r 
        JOIN nation n ON r.r_regionkey = n.n_regionkey 
        JOIN supplier s ON n.n_nationkey = s.s_nationkey 
        WHERE s.s_suppkey = ss.s_suppkey
        LIMIT 1
    )
ORDER BY 
    rs.total_region_sales DESC;