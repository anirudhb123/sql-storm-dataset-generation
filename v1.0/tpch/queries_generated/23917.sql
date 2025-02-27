WITH RECURSIVE sales_data AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_sales
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= date '2023-01-01' AND o.o_orderdate < date '2024-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
),
supplier_part_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        (p.p_retailprice * ps.ps_availqty) AS total_supply_value,
        RANK() OVER (PARTITION BY s.s_suppkey ORDER BY (p.p_retailprice * ps.ps_availqty) DESC) AS rank_supply
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    sd.c_name,
    ISNULL(spi.s_name, 'No Supplier') AS supplier_name,
    total_sales,
    COALESCE(spi.total_supply_value, 0) AS total_supply_value,
    CASE 
        WHEN total_sales > COALESCE(spi.total_supply_value, 0) THEN 'Sales Exceed Supply'
        WHEN total_sales < COALESCE(spi.total_supply_value, 0) THEN 'Supply Exceed Sales'
        ELSE 'Sales Equal Supply'
    END AS sales_vs_supply
FROM 
    sales_data sd
LEFT JOIN 
    supplier_part_info spi ON sd.c_custkey = spi.s_suppkey
WHERE 
    sd.rank_sales = 1 
    OR (sp.total_supply_value IS NULL AND sd.custkey IN (SELECT c_custkey FROM sales_data WHERE total_sales < 1000))
ORDER BY 
    total_sales DESC, supplier_name ASC;

WITH aggregated_results AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND CURDATE()
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ar.c_custkey,
    ar.c_name,
    CASE 
        WHEN ar.total_sales > 10000 THEN 'High Value Customer'
        WHEN ar.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_segment
FROM 
    aggregated_results ar
WHERE 
    ar.total_sales IS NOT NULL
    AND ar.c_custkey NOT IN (
        SELECT 
            c.c_custkey 
        FROM 
            customer c 
        WHERE 
            c.c_acctbal < 0
    )
ORDER BY 
    ar.total_sales DESC;
