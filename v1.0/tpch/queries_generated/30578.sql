WITH RECURSIVE sales_data AS (
    SELECT 
        c.c_custkey AS customer_key,
        c.c_name AS customer_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
top_customers AS (
    SELECT 
        customer_key, customer_name, total_sales
    FROM 
        sales_data
    WHERE 
        rank <= 10
),
supplier_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
region_sales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(sd.total_sales) AS region_sales_total
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        sales_data sd ON c.c_custkey = sd.customer_key
    GROUP BY 
        r.r_name
)
SELECT 
    r.region_name,
    rs.region_sales_total,
    COALESCE(si.s_name, 'No Supplier') AS supplier_name,
    si.part_count,
    si.total_supply_cost
FROM 
    region_sales rs
LEFT JOIN 
    supplier_info si ON si.part_count > 0
JOIN 
    region r ON r.r_name = rs.region_name
ORDER BY 
    rs.region_sales_total DESC, si.total_supply_cost ASC
LIMIT 15;
