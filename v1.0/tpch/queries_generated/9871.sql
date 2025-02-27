WITH TotalSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON l.l_partkey = p.p_partkey
    JOIN 
        orders o ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2021-01-01' AND o.o_orderdate < DATE '2022-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
SalesRanked AS (
    SELECT 
        ts.*,
        RANK() OVER (PARTITION BY ts.s_nationkey ORDER BY ts.total_sales DESC) AS sales_rank
    FROM 
        TotalSales ts
)
SELECT 
    r.r_name AS nation_name,
    COUNT(sr.s_suppkey) AS supplier_count,
    SUM(sr.total_sales) AS total_sales,
    AVG(sr.total_sales) AS avg_sales,
    MAX(sr.total_sales) AS max_sales
FROM 
    SalesRanked sr
JOIN 
    nation r ON sr.s_nationkey = r.n_nationkey
WHERE 
    sr.sales_rank <= 5
GROUP BY 
    r.r_name
ORDER BY 
    total_sales DESC;
