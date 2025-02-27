WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_mktsegment,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_mktsegment
),
TopSales AS (
    SELECT 
        r.mktsegment, 
        r.total_sales
    FROM 
        RankedOrders r
    WHERE 
        r.rn <= 5
),
RegionSales AS (
    SELECT 
        n.n_name AS region_name,
        SUM(ts.total_sales) AS region_sales
    FROM 
        nation n
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
        TopSales ts ON o.o_orderkey IN (SELECT o_orderkey FROM RankedOrders WHERE mktsegment = ts.mktsegment)
    GROUP BY 
        n.n_name
)
SELECT 
    r.region_name,
    r.region_sales,
    CASE 
        WHEN r.region_sales >= 1000000 THEN 'High'
        WHEN r.region_sales >= 500000 THEN 'Medium'
        ELSE 'Low' 
    END AS sales_category
FROM 
    RegionSales r
ORDER BY 
    r.region_sales DESC;
