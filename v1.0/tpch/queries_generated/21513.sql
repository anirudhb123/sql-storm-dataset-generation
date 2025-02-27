WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as Rnk
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        p.p_comment,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM 
        part p 
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, p.p_comment
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        SUM(l.l_quantity) AS TotalQuantity
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATEADD(DAY, -90, GETDATE())
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice
    HAVING 
        SUM(l.l_quantity) > 50
)
SELECT 
    r.r_name,
    COALESCE(SUM(hv.TotalSupplyCost), 0) AS TotalPartSupplyCost,
    COALESCE(SUM(ro.TotalQuantity), 0) AS TotalOrderQuantity,
    COUNT(DISTINCT s.s_suppkey) AS SupplierCount,
    COUNT(DISTINCT CASE 
        WHEN ro.o_totalprice IS NOT NULL THEN ro.o_orderkey 
        ELSE NULL END) AS TotalProcessedOrders
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    RankedSuppliers s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    HighValueParts hv ON hv.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
LEFT JOIN 
    RecentOrders ro ON ro.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_suppkey = s.s_suppkey)
WHERE 
    s.Rnk <= 5
GROUP BY 
    r.r_name
ORDER BY 
    r.r_name;
