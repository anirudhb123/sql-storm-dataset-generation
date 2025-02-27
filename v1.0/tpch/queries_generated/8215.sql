WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_phone,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_phone, s.s_nationkey
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        CUST.c_mktsegment
    FROM 
        orders o
    JOIN 
        customer CUST ON o.o_custkey = CUST.c_custkey
    WHERE 
        o.o_orderdate >= DATEADD(month, -6, GETDATE())
)
SELECT 
    R.r_name AS RegionName,
    R.r_comment AS RegionComment,
    S.s_name AS SupplierName,
    S.TotalCost AS TotalSupplierCost,
    RANK() OVER (PARTITION BY R.r_regionkey ORDER BY S.TotalCost DESC) AS SupplierRank,
    COUNT(RO.o_orderkey) AS RecentOrderCount
FROM 
    region R
JOIN 
    nation N ON R.r_regionkey = N.n_regionkey
JOIN 
    RankedSuppliers S ON N.n_nationkey = S.s_nationkey
LEFT JOIN 
    RecentOrders RO ON S.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = RO.o_orderkey))
GROUP BY 
    R.r_regionkey, R.r_name, R.r_comment, S.s_name, S.TotalCost
ORDER BY 
    R.r_regionkey, SupplierRank;
