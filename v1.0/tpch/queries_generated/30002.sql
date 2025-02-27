WITH RECURSIVE CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(ps_supplycost * ps_availqty) FROM partsupp ps)
),
RecentLargeOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalLineItemValue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATEADD(month, -6, GETDATE())
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT 
    co.c_name,
    hvs.s_name AS SupplierName,
    r.r_name AS Region,
    COUNT(DISTINCT co.o_orderkey) AS TotalOrders,
    SUM(rlo.TotalLineItemValue) AS TotalValueOfRecentLargeOrders
FROM 
    CustomerOrders co
LEFT JOIN 
    RecentLargeOrders rlo ON co.o_orderkey = rlo.o_orderkey
JOIN 
    supplier s ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps JOIN part p ON ps.ps_partkey = p.p_partkey WHERE p.p_size = 8)
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    HighValueSuppliers hvs ON s.s_suppkey = hvs.s_suppkey
WHERE 
    co.OrderRank = 1 AND
    hvs.TotalSupplyCost IS NOT NULL
GROUP BY 
    co.c_name, hvs.s_name, r.r_name
ORDER BY 
    TotalOrders DESC, TotalValueOfRecentLargeOrders DESC;
