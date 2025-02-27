WITH RankedSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        partsupp ps ON ps.ps_partkey = p.p_partkey
    JOIN 
        supplier s ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, s.s_name
),
TopSales AS (
    SELECT 
        p_partkey, 
        p_name,
        s_name,
        total_sales
    FROM 
        RankedSales
    WHERE 
        rank <= 5
),
RegionCheck AS (
    SELECT 
        n.n_nationkey,
        r.r_name,
        r.r_comment,
        COUNT(*) AS total_nations
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_nationkey, r.r_name, r.r_comment
    HAVING 
        COUNT(*) > 1
)
SELECT 
    ts.p_partkey, 
    ts.p_name, 
    ts.s_name, 
    rc.r_name, 
    rc.r_comment,
    COALESCE(SUM(l.l_quantity), 0) AS total_quantity,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) > 10 THEN 'Large',
        WHEN COUNT(DISTINCT o.o_orderkey) BETWEEN 1 AND 10 THEN 'Medium',
        ELSE 'Small' 
    END AS order_size_category
FROM 
    TopSales ts
LEFT JOIN 
    lineitem l ON ts.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
RIGHT JOIN 
    RegionCheck rc ON rc.n_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'Germany')
GROUP BY 
    ts.p_partkey, ts.p_name, ts.s_name, rc.r_name, rc.r_comment
HAVING 
    total_quantity > (SELECT AVG(total_quantity) FROM (
        SELECT 
            SUM(l_quantity) AS total_quantity
        FROM 
            lineitem
        GROUP BY 
            l_partkey
    ) AS avg_qty)
ORDER BY 
    ts.total_sales DESC, 
    rc.total_nations ASC;
