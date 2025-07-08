
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps.partkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
TotalSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '1996-01-01' AND l.l_shipdate < '1997-01-01'
    GROUP BY 
        l.l_partkey
),
AvailableParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(ps.ps_availqty, 0) AS available_quantity
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
),
TopPartSales AS (
    SELECT 
        tp.p_partkey, 
        tp.p_name, 
        ts.total_sales,
        ROW_NUMBER() OVER (ORDER BY ts.total_sales DESC) AS sales_rank
    FROM 
        AvailableParts tp
    JOIN 
        TotalSales ts ON tp.p_partkey = ts.l_partkey
    WHERE 
        tp.available_quantity > 0
)
SELECT 
    np.n_name AS nation_name,
    SUM(CASE WHEN ts.sales_rank <= 5 THEN ts.total_sales ELSE 0 END) AS top_5_sales,
    COUNT(DISTINCT rs.s_suppkey) AS distinct_suppliers,
    COUNT(CASE WHEN rs.rnk = 1 THEN 1 END) AS top_supplier_count,
    LISTAGG(DISTINCT rs.s_name, ', ') AS supplier_names
FROM 
    TopPartSales ts
JOIN 
    partsupp ps ON ts.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation np ON s.s_nationkey = np.n_nationkey
LEFT JOIN 
    RankedSuppliers rs ON rs.s_suppkey = s.s_suppkey
WHERE 
    ts.total_sales IS NOT NULL
GROUP BY 
    np.n_name
HAVING 
    SUM(ts.total_sales) > 10000
ORDER BY 
    top_5_sales DESC, distinct_suppliers ASC
LIMIT 10;
