WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        1 AS level
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    UNION ALL
    SELECT 
        sh.c_custkey,
        sh.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        sh.level + 1
    FROM 
        sales_hierarchy sh
    JOIN 
        orders o ON sh.o_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate < (CURRENT_DATE - INTERVAL '30 days') AND 
        sh.level < 3
), ranked_sales AS (
    SELECT 
        sh.c_custkey,
        sh.c_name,
        SUM(sh.o_totalprice) AS total_sales,
        RANK() OVER (PARTITION BY sh.c_custkey ORDER BY SUM(sh.o_totalprice) DESC) AS sales_rank
    FROM 
        sales_hierarchy sh
    GROUP BY 
        sh.c_custkey, sh.c_name
), part_stats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(ps.ps_partkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)

SELECT 
    rs.c_name,
    rs.total_sales,
    ps.p_name,
    ps.avg_supply_cost,
    COALESCE(ps.supplier_count, 0) AS supplier_count,
    CASE 
        WHEN rs.total_sales > 10000 THEN 'Gold'
        WHEN rs.total_sales BETWEEN 5000 AND 10000 THEN 'Silver'
        ELSE 'Bronze'
    END AS customer_tier
FROM 
    ranked_sales rs
LEFT JOIN 
    part_stats ps ON rs.sales_rank = ps.p_partkey
WHERE 
    rs.total_sales IS NOT NULL
ORDER BY 
    rs.total_sales DESC
FETCH FIRST 10 ROWS ONLY;
