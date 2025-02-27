WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS OrderCount,
        AVG(o.o_totalprice) AS AvgOrderPrice
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    COALESCE(ns.n_name, 'Unknown Nation') AS NationName,
    COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
    CASE WHEN COUNT(DISTINCT c.c_custkey) > 0 THEN 'Active' ELSE 'Inactive' END AS CustomerStatus,
    ARRAY_AGG(DISTINCT s.s_name ORDER BY s.s_name) AS SupplierNames
FROM 
    nation ns
LEFT JOIN 
    customer c ON c.c_nationkey = ns.n_nationkey 
LEFT JOIN 
    orders o ON o.o_custkey = c.c_custkey 
LEFT JOIN 
    lineitem l ON l.l_orderkey = o.o_orderkey 
LEFT JOIN 
    RankedSuppliers rs ON rs.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 10))
WHERE 
    (l.l_shipdate IS NOT NULL AND o.o_orderstatus = 'O' OR l.l_returnflag = 'R')
    AND (c.c_acctbal IS NOT NULL AND c.c_mktsegment = 'BUILDING')
GROUP BY 
    ns.n_name 
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 
    (SELECT COALESCE(AVG(SUM(l2.l_extendedprice * (1 - l2.l_discount))), 0)
     FROM orders o2
     JOIN lineitem l2 ON l2.l_orderkey = o2.o_orderkey 
     WHERE o2.o_orderstatus = 'O' 
     GROUP BY o2.o_custkey)
ORDER BY 
    TotalRevenue DESC;
