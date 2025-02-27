WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > (SELECT AVG(ps_availqty) FROM partsupp) 
        AND s.s_acctbal IS NOT NULL
),
TopSales AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales
    FROM 
        customer c 
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31' 
        AND l.l_discount BETWEEN 0.05 AND 0.15
    GROUP BY 
        c.c_custkey
),
SalesAverage AS (
    SELECT 
        AVG(TotalSales) AS AvgTotalSales
    FROM 
        TopSales
)
SELECT 
    ps.ps_partkey,
    p.p_name,
    R.s_name AS TopSupplier,
    COALESCE(SA.AvgTotalSales, 0) AS AvgCustomerSales,
    (SELECT COUNT(DISTINCT c.c_custkey) 
     FROM customer c 
     JOIN orders o ON c.c_custkey = o.o_custkey 
     WHERE o.o_orderstatus = 'O' AND c.c_acctbal > (SELECT MIN(c_acctbal) FROM customer WHERE c_acctbal IS NOT NULL)
    ) AS ActiveCustomers
FROM 
    partsupp ps
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    RankedSuppliers R ON ps.ps_suppkey = R.s_suppkey AND R.SupplierRank = 1
CROSS JOIN 
    SalesAverage SA
WHERE 
    p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_container IS NOT NULL) 
    AND p.p_retailprice < ALL (SELECT AVG(p_retailprice) FROM part GROUP BY p_type)
    AND p.p_comment LIKE '%special%'
ORDER BY 
    p.p_partkey DESC;
