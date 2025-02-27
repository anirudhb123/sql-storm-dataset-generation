WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) as SuppRank,
        COUNT(CASE WHEN ps.ps_availqty < 100 THEN 1 END) OVER (PARTITION BY s.s_suppkey) AS LowStockCount
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSpend
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey AND o.o_orderdate >= '2023-01-01'
    GROUP BY 
        c.c_custkey
),
FilteredNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS RegionName
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        r.r_name LIKE 'A%' OR n.n_comment IS NULL
),
SuppliersWithOrders AS (
    SELECT 
        su.s_suppkey,
        su.s_name,
        co.OrderCount,
        co.TotalSpend
    FROM 
        RankedSuppliers su
    LEFT JOIN 
        CustomerOrders co ON su.SuppRank = 1
    WHERE 
        su.LowStockCount > 2
)
SELECT 
    fn.n_name AS NationName,
    swo.s_name AS SupplierName,
    swo.OrderCount,
    swo.TotalSpend,
    CASE 
        WHEN swo.TotalSpend IS NULL THEN 'No Orders'
        WHEN swo.TotalSpend >= 10000 THEN 'High Value'
        ELSE 'Moderate Value'
    END AS OrderValueCategory,
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
FROM 
    SuppliersWithOrders swo
JOIN 
    lineitem l ON l.l_suppkey = swo.s_suppkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
JOIN 
    FilteredNations fn ON swo.s_suppkey = fn.n_nationkey
GROUP BY 
    fn.n_name, swo.s_name, swo.OrderCount, swo.TotalSpend, p.p_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
ORDER BY 
    OrderValueCategory DESC, TotalRevenue DESC;
