WITH RankedSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_sales,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * l.l_quantity) DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT 
        nation,
        s_suppkey,
        s_name,
        total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 3
)
SELECT 
    r.r_name AS region,
    t.nation,
    COUNT(t.s_suppkey) AS num_top_suppliers,
    SUM(t.total_sales) AS total_sales_sum
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    TopSuppliers t ON n.n_nationkey = t.n_suppkey
GROUP BY 
    r.r_name, t.nation
ORDER BY 
    r.r_name, num_top_suppliers DESC;
