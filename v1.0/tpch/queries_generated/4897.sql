WITH SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), 
CustomerOrderCount AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    COALESCE(sr.total_revenue, 0) AS supplier_revenue,
    COALESCE(coc.order_count, 0) AS customer_order_count,
    CASE 
        WHEN COALESCE(sr.total_revenue, 0) > 100000 THEN 'High Revenue' 
        ELSE 'Low Revenue' 
    END AS revenue_category
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierRevenue sr ON s.s_suppkey = sr.s_suppkey
LEFT JOIN 
    CustomerOrderCount coc ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = coc.c_custkey) 
WHERE 
    (sr.total_revenue IS NOT NULL OR coc.order_count > 0) 
    AND s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_availqty > 50)
ORDER BY 
    region_name, nation_name;
