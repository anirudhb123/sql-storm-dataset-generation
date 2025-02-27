WITH RegionalSales AS (
    SELECT 
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT c.c_custkey) AS unique_customers,
        RANK() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
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
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        l.l_shipdate >= CURRENT_DATE - INTERVAL '1 year'
        AND l.l_returnflag = 'N'
        AND p.p_size IS NOT NULL
    GROUP BY 
        r.r_name
),
TopRegions AS (
    SELECT 
        r_name, 
        total_sales,
        unique_customers
    FROM 
        RegionalSales
    WHERE 
        sales_rank <= 5
)
SELECT 
    tr.r_name,
    tr.total_sales,
    CASE 
        WHEN tr.unique_customers < 10 THEN 'Low Customer Engagement'
        WHEN tr.unique_customers BETWEEN 10 AND 50 THEN 'Moderate Customer Engagement'
        ELSE 'High Customer Engagement'
    END AS engagement_level,
    COALESCE((SELECT AVG(supply_cost) FROM partsupp WHERE ps_partkey IN (SELECT p_partkey FROM part WHERE p_brand LIKE 'Brand%')), 0) AS avg_supply_cost,
    STRING_AGG(DISTINCT s.s_name, ', ') FILTER (WHERE s.s_acctbal > 1000) AS high_status_suppliers
FROM 
    TopRegions tr
LEFT JOIN 
    partsupp ps ON ps.ps_partkey IN (SELECT p_partkey FROM part WHERE p_name IS NOT NULL)
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    tr.r_name, tr.total_sales, tr.unique_customers
ORDER BY 
    tr.total_sales DESC NULLS LAST;
