WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' 
        AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT 
        s.*,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS rank
    FROM 
        SupplierSales s
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    sr.s_name AS supplier_name,
    sr.total_revenue,
    sr.order_count
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    RankedSuppliers sr ON n.n_nationkey = sr.s_nationkey
WHERE 
    sr.rank <= 5 OR sr.rank IS NULL
ORDER BY 
    region_name, nation_name, total_revenue DESC;
