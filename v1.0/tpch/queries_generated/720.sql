WITH SupplierSales AS (
    SELECT 
        s.s_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales,
        COUNT(DISTINCT o.o_orderkey) AS OrderCount
    FROM 
        supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) 
        AND l.l_shipdate >= DATE '2023-01-01'
    GROUP BY s.s_name
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
TopSuppliers AS (
    SELECT 
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (ORDER BY ss.TotalSales DESC) AS SalesRank
    FROM 
        supplier s
    JOIN SupplierSales ss ON s.s_name = ss.s_name
)
SELECT 
    ts.s_name, 
    ts.s_acctbal, 
    COALESCE(ts.SalesRank, 0) AS SalesRank,
    (SELECT COUNT(DISTINCT ps.ps_partkey) FROM partsupp ps WHERE ps.ps_suppkey = (SELECT s.s_suppkey FROM supplier s WHERE s.s_name = ts.s_name)) AS UniquePartsSupplied
FROM 
    TopSuppliers ts
FULL OUTER JOIN region r ON (r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_name = ts.s_name)))
WHERE 
    (r.r_name IS NOT NULL) OR (ts.s_acctbal < 5000)
ORDER BY 
    ts.SalesRank NULLS LAST;
