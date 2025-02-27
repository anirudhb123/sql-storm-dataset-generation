WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS RankInNation
    FROM
        supplier s
    INNER JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
TopSuppliers AS (
    SELECT 
        s.*
    FROM 
        SupplierStats s
    WHERE 
        s.RankInNation <= 3
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) IS NOT NULL
),
SupplierCustomerConnections AS (
    SELECT 
        DISTINCT cs.c_custkey,
        cs.c_name,
        ss.s_name AS SupplierName,
        ss.TotalSupplyCost
    FROM 
        CustomerOrders cs
    LEFT JOIN 
        lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cs.c_custkey)
    LEFT JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    LEFT JOIN 
        TopSuppliers ss ON ps.ps_suppkey = ss.s_suppkey
)
SELECT 
    COALESCE(c.c_name, 'Unknown Customer') AS CustomerName,
    COUNT(DISTINCT s.SupplierName) AS NumberOfSuppliers,
    SUM(s.TotalSupplyCost) AS TotalSupplierCost,
    (SELECT COUNT(*) FROM orders o WHERE o.o_custkey = c.c_custkey) AS NumberOfOrders
FROM 
    CustomerOrders c
LEFT JOIN 
    SupplierCustomerConnections s ON c.c_custkey = s.c_custkey
GROUP BY 
    c.c_custkey, c.c_name
HAVING 
    SUM(s.TotalSupplyCost) > 100000 OR COUNT(s.SupplierName) > 5
ORDER BY 
    TotalSupplierCost DESC
LIMIT 10;
