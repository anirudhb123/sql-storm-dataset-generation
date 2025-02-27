WITH SupplierSales AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
NationsSales AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        SUM(ss.total_sales) AS nation_sales
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    GROUP BY 
        n.n_nationkey, n.n_name
) 
SELECT 
    r.r_name AS region_name, 
    ns.n_name AS nation_name, 
    ns.nation_sales
FROM 
    region r
JOIN 
    nation ns ON r.r_regionkey = ns.n_regionkey
JOIN 
    NationsSales ns ON ns.n_nationkey = ns.n_nationkey
ORDER BY 
    r.r_name, ns.nation_sales DESC;
