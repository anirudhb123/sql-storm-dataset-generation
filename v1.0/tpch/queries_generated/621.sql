WITH regional_sales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
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
    WHERE 
        o.o_orderdate >= '2023-01-01' 
        AND o.o_orderdate < '2024-01-01'
    GROUP BY 
        r.r_name
), sales_ranked AS (
    SELECT 
        region_name,
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        regional_sales
), customer_summary AS (
    SELECT 
        c.c_name AS customer_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS national_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 0
    GROUP BY 
        c.c_nationkey, c.c_name
)
SELECT 
    r.region_name,
    s.total_sales,
    s.order_count,
    c.customer_name,
    c.total_spent,
    c.total_orders
FROM 
    sales_ranked s
FULL OUTER JOIN 
    customer_summary c ON s.region_name = (SELECT n.r_name 
                                             FROM nation n 
                                             WHERE n.n_nationkey = (SELECT s.s_nationkey 
                                                                    FROM supplier s 
                                                                    WHERE s.s_suppkey = (SELECT ps.ps_suppkey 
                                                                                         FROM partsupp ps 
                                                                                         WHERE ps.ps_partkey = (SELECT p.p_partkey 
                                                                                                                  FROM part p 
                                                                                                                  WHERE p.p_brand = 'Brand#18' 
                                                                                                                  LIMIT 1)))
                                             LIMIT 1)
ORDER BY 
    s.sales_rank, c.national_rank
