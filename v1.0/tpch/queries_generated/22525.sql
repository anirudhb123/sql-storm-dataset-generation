WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) as BalRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
NationRegion AS (
    SELECT 
        n.n_name, 
        r.r_name, 
        COUNT(DISTINCT s.s_suppkey) as SupplierCount
    FROM 
        nation n 
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name, r.r_name
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate, 
        COUNT(DISTINCT li.l_orderkey) as LineCount
    FROM 
        orders o 
    LEFT JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) * 1.2 FROM orders o2)
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate
)
SELECT 
    nv.n_name AS Nation, 
    r.r_name AS Region, 
    NVL(sh.SupplierCount, 0) AS SupplierCount,
    COUNT(DISTINCT ho.o_orderkey) AS OrderCount,
    SUM(ho.o_totalprice) AS TotalSales,
    MAX(rn.s_name) AS TopSupplier,
    AVG(ho.LineCount) AS AvgLinesPerOrder
FROM 
    NationRegion nv
LEFT JOIN 
    (SELECT DISTINCT n_name, r_name, SupplierCount FROM NationRegion) sh ON 
    nv.n_name = sh.n_name AND nv.r_name = sh.r_name
LEFT JOIN 
    HighValueOrders ho ON nv.n_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = (SELECT TOP 1 s2.s_suppkey FROM supplier s2 WHERE s2.s_acctbal IS NOT NULL ORDER BY s2.s_acctbal DESC)))
LEFT JOIN 
    RankedSuppliers rn ON rn.BalRank = 1 AND rn.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps ORDER BY ps.ps_supplycost DESC LIMIT 1)
GROUP BY 
    nv.n_name, r.r_name
HAVING 
    SUM(ho.o_totalprice) IS NOT NULL AND 
    MAX(rn.s_name) IS NOT NULL
ORDER BY 
    TotalSales DESC, OrderCount DESC;
