WITH regional_sales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
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
    GROUP BY 
        r.r_name
), 
top_regions AS (
    SELECT 
        region_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        regional_sales
)
SELECT 
    tr.region_name,
    tr.total_sales,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    AVG(s.s_acctbal) AS avg_supplier_balance
FROM 
    top_regions tr
JOIN 
    nation n ON tr.region_name = (SELECT r.r_name FROM region r JOIN nation n2 ON r.r_regionkey = n2.n_regionkey WHERE n2.n_nationkey = n.n_nationkey)
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
WHERE 
    tr.sales_rank <= 5
GROUP BY 
    tr.region_name, tr.total_sales
ORDER BY 
    tr.total_sales DESC;
