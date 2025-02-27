WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
TotalLineItemSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '2023-01-01' AND l.l_shipdate < DATE '2024-01-01'
    GROUP BY 
        l.l_partkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(ts.total_sales, 0) AS total_sales
    FROM 
        part p
    LEFT JOIN 
        TotalLineItemSales ts ON p.p_partkey = ts.l_partkey
    WHERE 
        p.p_retailprice > 100
)
SELECT 
    r.r_name,
    p.p_name,
    p.total_sales,
    s.s_name AS top_supplier
FROM 
    HighValueParts p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey AND s.rn = 1
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.total_sales > 1000
ORDER BY 
    r.r_name, p.total_sales DESC;
