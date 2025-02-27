WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
),
OrderSummary AS (
    SELECT 
        o.o_custkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSpent,
        COUNT(o.o_orderkey) AS TotalOrders
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
    GROUP BY 
        o.o_custkey
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COALESCE(o.TotalSpent, 0) AS TotalSpent,
        COALESCE(o.TotalOrders, 0) AS TotalOrders
    FROM 
        customer c
    LEFT JOIN 
        OrderSummary o ON c.c_custkey = o.o_custkey
)
SELECT 
    r.r_name AS Region,
    SUM(cd.TotalSpent) AS TotalCustomerSpending,
    COUNT(DISTINCT cd.c_custkey) AS UniqueCustomers,
    MAX(s.SupplierRank) AS TopSupplierRank
FROM 
    CustomerDetails cd
LEFT JOIN 
    nation n ON cd.c_nationkey = n.n_nationkey
LEFT JOIN 
    RankedSuppliers s ON n.n_name = s.n_name AND s.SupplierRank <= 2
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    r.r_name
HAVING 
    SUM(cd.TotalSpent) > 1000000
ORDER BY 
    TotalCustomerSpending DESC;
