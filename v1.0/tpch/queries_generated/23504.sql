WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        * 
    FROM 
        RankedSuppliers
    WHERE 
        Rank <= 3
)
SELECT 
    n.n_name,
    COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END), 0) AS TotalReturns,
    COALESCE(MAX(o.o_orderdate), '1900-01-01') AS LastOrderDate,
    COUNT(DISTINCT c.c_custkey) FILTER (WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 100.00) AS ActiveCustomers,
    STRING_AGG(DISTINCT ps.ps_comment, ', ') AS UniqueComments
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    n.n_name IS NOT NULL
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 1 AND
    SUM(l.l_quantity) IS NOT NULL
ORDER BY 
    TotalReturns DESC NULLS LAST;
