WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        1 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000
    
    UNION ALL
    
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        sh.level + 1
    FROM 
        supplier s
    JOIN 
        SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE 
        s.s_acctbal > sh.s_acctbal
),
TotalOrderValue AS (
    SELECT 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalValue,
        COUNT(o.o_orderkey) AS OrderCount
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_custkey
),
NationSupplier AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS SupplierCount
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    p.p_name,
    p.p_brand,
    ph.level AS SupplierLevel,
    COALESCE(n.n_name, 'Unknown') AS Nation,
    COALESCE(ts.OrderCount, 0) AS OrdersPlaced,
    COALESCE(ts.TotalValue, 0) AS TotalOrderValue,
    ns.SupplierCount,
    p.p_retailprice * (1 - COALESCE(AVG(l.l_discount), 0)) AS DiscountedRetailPrice
FROM 
    part p
LEFT JOIN 
    SupplierHierarchy ph ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ph.s_suppkey)
LEFT JOIN 
    TotalOrderValue ts ON ts.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'United States'))
LEFT JOIN 
    NationSupplier ns ON ns.n_name = COALESCE(n.n_name, 'Unknown')
LEFT JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN 
    nation n ON n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = ph.s_suppkey LIMIT 1)
WHERE 
    p.p_size BETWEEN 10 AND 20
ORDER BY 
    TotalOrderValue DESC, SupplierLevel ASC;
