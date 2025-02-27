WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSpent,
        ROW_NUMBER() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS CustomerRank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(DISTINCT o.o_orderkey) > 5
)
SELECT 
    r.r_name AS Region,
    ns.n_name AS Nation,
    COUNT(DISTINCT c.c_custkey) AS CustomerCount,
    SUM(co.TotalSpent) AS TotalCustomerSpending,
    AVG(co.OrderCount) AS AvgOrdersPerCustomer,
    SUM(rs.TotalCost) AS TotalSupplierCost,
    COUNT(DISTINCT rs.s_suppkey) AS ActiveSuppliers
FROM 
    RankedSuppliers rs
JOIN 
    nation ns ON rs.n_nationkey = ns.n_nationkey
JOIN 
    region r ON ns.n_regionkey = r.r_regionkey
JOIN 
    CustomerOrders co ON rs.n_nationkey = co.c_nationkey
GROUP BY 
    r.r_name, ns.n_name
ORDER BY 
    TotalCustomerSpending DESC, CustomerCount DESC;
