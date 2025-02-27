WITH supplier_order_data AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
), top_suppliers AS (
    SELECT * 
    FROM supplier_order_data 
    WHERE sales_rank <= 5
), customer_region AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        r.r_name AS region_name, 
        SUM(o.o_totalprice) AS total_spending, 
        DENSE_RANK() OVER (PARTITION BY r.r_name ORDER BY SUM(o.o_totalprice) DESC) AS spending_rank
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= '2022-01-01'
    GROUP BY 
        c.c_custkey, c.c_name, r.r_name
), combined_data AS (
    SELECT 
        ts.s_name AS supplier_name, 
        ts.total_sales, 
        cr.region_name, 
        cr.total_spending
    FROM 
        top_suppliers ts
    FULL OUTER JOIN 
        customer_region cr ON cr.spending_rank = 1
)
SELECT 
    COALESCE(supplier_name, 'Unspecified Supplier') AS supplier_name,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(region_name, 'Unknown Region') AS region_name,
    COALESCE(total_spending, 0) AS total_spending
FROM 
    combined_data
WHERE 
    total_sales > 10000 OR region_name IS NOT NULL
ORDER BY 
    total_spending DESC, total_sales ASC;

