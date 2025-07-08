
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 0
),
TotalSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
    GROUP BY 
        l.l_partkey
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(ts.total_revenue, 0) AS revenue,
        COUNT(ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        TotalSales ts ON p.p_partkey = ts.l_partkey
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, ts.total_revenue
)
SELECT 
    fp.p_partkey,
    fp.p_name,
    fp.revenue,
    fs.s_name AS top_supplier,
    fs.s_acctbal
FROM 
    FilteredParts fp
LEFT JOIN 
    RankedSuppliers fs ON fp.p_partkey = fs.p_partkey 
WHERE 
    fp.revenue > (SELECT AVG(revenue) FROM FilteredParts)
ORDER BY 
    fp.revenue DESC, fp.p_partkey
LIMIT 10;
