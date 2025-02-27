WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderstatus = 'O')
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
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
ValidPartSupply AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        ps.ps_availqty, 
        ps.ps_supplycost,
        CASE 
            WHEN ps.ps_availqty IS NULL THEN 0 
            ELSE ps.ps_availqty 
        END AS ValidQty
    FROM 
        partsupp ps
    WHERE 
        ps.ps_supplycost < (SELECT AVG(ps2.ps_supplycost) FROM partsupp ps2)
    UNION ALL
    SELECT 
        ps.ps_partkey, 
        -ps.ps_suppkey, 
        NULL, 
        NULL, 
        NULL
    FROM 
        partsupp ps
    WHERE 
        ps.ps_supplycost IS NULL
)
SELECT 
    n.n_name AS Nation, 
    r.r_name AS Region, 
    SUM(COALESCE(l.l_extendedprice, 0)) AS TotalRevenue,
    COUNT(DISTINCT o.o_orderkey) AS NumberOfOrders,
    MAX(CASE WHEN so.s_suppkey IS NOT NULL THEN 'Available' ELSE 'Not Available' END) AS SupplyStatus
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    supplier so ON n.n_nationkey = so.s_nationkey
LEFT JOIN 
    lineitem l ON l.l_orderkey IN (SELECT o_orderkey FROM RankedOrders WHERE OrderRank <= 10)
JOIN 
    ValidPartSupply ps ON l.l_partkey = ps.ps_partkey
JOIN 
    HighValueSuppliers hvs ON hvs.s_suppkey = ps.ps_suppkey
WHERE 
    r.r_name LIKE 'E%'
    AND (SUM(ps.ValidQty) > 1000 OR EXISTS (SELECT 1 FROM orders o WHERE o.o_orderkey = l.l_orderkey AND o.o_orderstatus = 'O'))
GROUP BY 
    n.n_name, r.r_name
HAVING 
    SUM(COALESCE(l.l_extendedprice, 0)) IS NOT NULL
    AND COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    TotalRevenue DESC, 
    NumberOfOrders ASC;
