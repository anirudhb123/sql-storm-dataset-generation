WITH RECURSIVE Sales_CTE AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_sales,
        RANK() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
Regional_Suppliers AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
),
Top_Sales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS top_rank
    FROM 
        Sales_CTE
    WHERE 
        sales_rank <= 10
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_container,
    COALESCE(sum(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
    COALESCE(rs.supplier_count, 0) AS total_suppliers,
    CASE 
        WHEN total_revenue > 10000 THEN 'High Revenue'
        WHEN total_revenue BETWEEN 5000 AND 10000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    (SELECT DISTINCT 
        ps_partkey,
        SUM(ps_supplycost) AS total_supplycost
     FROM 
        partsupp 
     GROUP BY 
        ps_partkey) AS ps_total ON p.p_partkey = ps_total.ps_partkey
LEFT JOIN 
    Regional_Suppliers rs ON p.p_mfgr = rs.nation_name
WHERE 
    p.p_retailprice IS NOT NULL 
    AND p.p_size IN (SELECT DISTINCT ps.ps_availqty FROM partsupp ps WHERE ps.ps_availqty > 0)
GROUP BY 
    p.p_partkey, p.p_name, p.p_container, rs.supplier_count
HAVING 
    total_revenue > 0
ORDER BY 
    total_revenue DESC
FETCH FIRST 20 ROWS ONLY;
