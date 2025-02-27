WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        o.o_orderstatus, 
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
), 
SupplierPartInfo AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        COALESCE(SUM(ps.ps_availqty), 0) AS TotalAvailableQty, 
        COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS TotalSupplyCost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
), 
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
)

SELECT 
    r.n_name AS NationName, 
    sp.p_name AS PartName, 
    sp.TotalAvailableQty, 
    sp.TotalSupplyCost, 
    co.TotalSpent, 
    ro.o_orderkey, 
    ro.o_orderdate
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierPartInfo sp ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = sp.p_partkey)
JOIN 
    CustomerOrderSummary co ON s.s_suppkey IN (SELECT s2.s_suppkey FROM supplier s2 JOIN partsupp ps2 ON s2.s_suppkey = ps2.ps_suppkey WHERE ps2.ps_partkey IN (SELECT p2.p_partkey FROM part p2 WHERE p2.p_name LIKE '%widget%'))
LEFT JOIN 
    RankedOrders ro ON ro.o_orderkey IN (SELECT o2.o_orderkey FROM orders o2 WHERE o2.o_orderstatus = 'O' AND o2.o_totalprice > 100)
WHERE 
    sp.TotalAvailableQty > 0 
    AND (co.TotalSpent IS NULL OR co.TotalSpent >= 500)
ORDER BY 
    r.n_name, sp.TotalSupplyCost DESC;
