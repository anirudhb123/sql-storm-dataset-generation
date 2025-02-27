WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost ASC) AS CostRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal, 
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS CustRank
    FROM 
        customer c
    WHERE 
        c.c_acctbal > 10000
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice ELSE 0 END), 0) AS TotalReturns,
    COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
    AVG(si.SupplyCost) AS AverageSupplyCost,
    CONCAT('Supplier: ', s.s_name, ', Region: ', n.n_name) AS SupplierAndRegion
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
GROUP BY 
    p.p_partkey, p.p_name
HAVING 
    TotalOrders > 0 AND 
    EXISTS (SELECT 1 FROM HighValueCustomers hv WHERE hv.c_custkey = o.o_custkey AND hv.CustRank <= 5)
ORDER BY 
    TotalReturns DESC;
