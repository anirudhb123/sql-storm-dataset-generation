WITH RECURSIVE SalesCTE AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS TotalSales,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS SalesRank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 1000
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS SupplierTotalSales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
),
NationsWithSales AS (
    SELECT 
        n.n_name,
        SUM(SupplierTotalSales) AS TotalSupplierSales
    FROM 
        nation n
    JOIN 
        SupplierSales ss ON ss.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps JOIN part p ON ps.ps_partkey = p.p_partkey WHERE p.p_size > 10)
    GROUP BY 
        n.n_name
)
SELECT 
    n.n_name,
    COALESCE(SUM(s.TotalSales), 0) AS CustomerSales,
    COALESCE(t.TotalSupplierSales, 0) AS SupplierSales
FROM 
    nation n
LEFT JOIN 
    SalesCTE s ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = s.c_custkey LIMIT 1)
LEFT JOIN 
    NationsWithSales t ON n.n_name = t.n_name
WHERE 
    n.n_nationkey IS NOT NULL
GROUP BY 
    n.n_name, t.TotalSupplierSales
ORDER BY 
    CustomerSales DESC, SupplierSales DESC;
