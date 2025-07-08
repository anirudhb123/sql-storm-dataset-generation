
WITH regional_sales AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        n.n_name, r.r_name
), sales_ranked AS (
    SELECT 
        nation_name,
        region_name,
        total_sales,
        total_orders,
        RANK() OVER (PARTITION BY region_name ORDER BY total_sales DESC) AS sales_rank
    FROM 
        regional_sales
), supplier_details AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey) AS supply_count,
        MAX(ps.ps_supplycost) AS max_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
)
SELECT 
    sr.nation_name,
    sr.region_name,
    sr.total_sales,
    sr.total_orders,
    sd.s_name AS supplier_name,
    sd.supply_count,
    sd.max_supply_cost,
    (CASE 
        WHEN sr.sales_rank = 1 THEN 'Top Performer'
        ELSE 'Regular'
    END) AS performance_status
FROM 
    sales_ranked sr
LEFT JOIN 
    supplier_details sd ON (sd.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = sr.nation_name) OR sd.s_nationkey IS NULL)
WHERE 
    sr.total_sales IS NOT NULL 
    AND (sr.region_name LIKE '%North%' OR sr.region_name IS NULL)
ORDER BY 
    sr.region_name, sr.total_sales DESC
LIMIT 100;
