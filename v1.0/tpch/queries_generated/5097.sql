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
PopularParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(l.l_quantity) > 100
),
NationsWithHighSales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(ss.total_sales) AS total_nation_sales
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    GROUP BY 
        n.n_nationkey, n.n_name
    HAVING 
        SUM(ss.total_sales) > 10000
)
SELECT 
    n.n_name AS nation,
    pp.p_name AS popular_part,
    pp.total_quantity,
    nh.total_nation_sales
FROM 
    PopularParts pp
JOIN 
    NationsWithHighSales nh ON nh.total_nation_sales > 0
JOIN 
    nation n ON n.n_nationkey IN (SELECT s_nationkey FROM supplier WHERE s_suppkey IN (SELECT s_suppkey FROM SupplierSales WHERE total_sales > 1000))
ORDER BY 
    nh.total_nation_sales DESC, pp.total_quantity DESC;
