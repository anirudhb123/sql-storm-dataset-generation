WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyValue,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        DENSE_RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O' AND
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
),
LineItemAggregates AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalLineItemValue
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
NullCheck AS (
    SELECT 
        p.p_partkey,
        p.p_retailprice,
        p.p_size
    FROM 
        part p
    WHERE 
        p.p_size IS NULL OR 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size IS NOT NULL)
)
SELECT 
    r.r_name,
    COUNT(DISTINCT ns.s_suppkey) AS NumberOfSuppliers,
    SUM(rsa.TotalSupplyValue) AS TotalSupplyCost,
    AVG(COALESCE(lia.TotalLineItemValue, 0)) AS AverageLineItemValue,
    COUNT(DISTINCT ro.o_orderkey) AS RecentOrderCount
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    RankedSuppliers ns ON n.n_nationkey = ns.s_nationkey AND ns.Rank <= 5
LEFT JOIN 
    LineItemAggregates lia ON lia.l_orderkey IN (SELECT o.o_orderkey FROM RecentOrders o)
LEFT JOIN 
    NullCheck p ON p.p_size IS NOT NULL
GROUP BY 
    r.r_name
HAVING 
    AVG(p.p_retailprice) > 100 AND
    COUNT(*) FILTER (WHERE ns.TotalSupplyValue IS NOT NULL) > 10
ORDER BY 
    TotalSupplyCost DESC NULLS LAST;
