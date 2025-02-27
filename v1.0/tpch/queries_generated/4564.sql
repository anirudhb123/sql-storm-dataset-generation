WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS rank
    FROM 
        customer c
),
TotalSales AS (
    SELECT 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATEADD(month, -6, GETDATE())
    GROUP BY 
        o.o_custkey
),
FrequentSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s1.s_acctbal) FROM supplier s1)
    GROUP BY 
        ps.ps_suppkey
    HAVING 
        COUNT(DISTINCT ps.ps_partkey) >= 5
)
SELECT 
    rc.c_custkey,
    rc.c_name,
    rc.c_acctbal,
    COALESCE(ts.total_sales, 0) AS total_sales,
    fs.part_count,
    CASE 
        WHEN fs.part_count IS NOT NULL THEN 'Frequent Supplier'
        ELSE 'Rare Supplier'
    END AS supplier_status,
    r.r_name AS customer_region
FROM 
    RankedCustomers rc
LEFT JOIN 
    TotalSales ts ON rc.c_custkey = ts.o_custkey
LEFT JOIN 
    FrequentSuppliers fs ON rc.c_custkey = fs.ps_suppkey
JOIN 
    nation n ON rc.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    rc.rank <= 5
ORDER BY 
    rc.c_acctbal DESC;
