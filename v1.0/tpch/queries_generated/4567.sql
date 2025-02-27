WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
TotalSales AS (
    SELECT 
        l.l_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    INNER JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        l.l_suppkey
),
TopSales AS (
    SELECT 
        ts.l_suppkey,
        ts.total_sales,
        RANK() OVER (ORDER BY ts.total_sales DESC) AS sales_rank
    FROM 
        TotalSales ts
    WHERE 
        ts.total_sales > 10000
)
SELECT 
    n.n_name,
    r.r_name,
    s.s_name,
    COALESCE(ts.total_sales, 0) AS total_sales,
    COALESCE(s.rank, 0) AS rank
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    RankedSuppliers s ON n.n_nationkey = s.s_nationkey AND s.rank <= 3
LEFT JOIN 
    TopSales ts ON s.s_suppkey = ts.l_suppkey
WHERE 
    ts.total_sales IS NOT NULL OR s.rank IS NOT NULL
ORDER BY 
    n.n_name, r.r_name, total_sales DESC;
