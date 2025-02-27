WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        COUNT(DISTINCT ps.ps_partkey) AS PartCount
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS TotalSpent,
        COUNT(o.o_orderkey) AS OrderCount
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
Sales AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS Revenue,
        o.o_orderpriority
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        l.l_orderkey, o.o_orderpriority
)
SELECT 
    n.n_name AS NationName,
    r.r_name AS RegionName,
    AVG(cs.TotalSpent) AS AvgCustomerSpending,
    AVG(ss.TotalCost) AS AvgSupplierCost,
    SUM(s.Revenue) AS TotalSalesRevenue
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    CustomerOrders cs ON n.n_nationkey = cs.c_custkey
LEFT JOIN 
    SupplierStats ss ON n.n_nationkey = (SELECT s_nationkey FROM supplier WHERE s_suppkey = ss.s_suppkey)
LEFT JOIN 
    Sales s ON s.l_orderkey IN (SELECT o_orderkey FROM orders WHERE o_custkey = cs.c_custkey)
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    TotalSalesRevenue DESC, AvgCustomerSpending DESC;
