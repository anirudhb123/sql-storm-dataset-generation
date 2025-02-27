WITH RECURSIVE Sales_CTE AS (
    SELECT 
        c.c_name AS customer_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_name
),
Supplier_Summary AS (
    SELECT 
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name
),
Region_Analysis AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        STRING_AGG(s.s_name, ', ') AS suppliers
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
)
SELECT 
    r.r_name AS region,
    ra.nation_count,
    sa.total_parts,
    sa.avg_supply_cost,
    sc.customer_name,
    sc.total_sales
FROM 
    Region_Analysis ra
LEFT JOIN 
    Supplier_Summary sa ON ra.suppliers LIKE '%' || sa.s_name || '%'
LEFT JOIN 
    Sales_CTE sc ON sc.sales_rank = 1
WHERE 
    ra.nation_count > 2
ORDER BY 
    ra.nation_count DESC, 
    sc.total_sales DESC
LIMIT 10;
