
WITH RECURSIVE OrderCTE AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        1 AS OrderLevel
    FROM orders o
    WHERE o.o_orderstatus = 'F'
    
    UNION ALL
    
    SELECT 
        o2.o_orderkey,
        o2.o_orderdate,
        o2.o_totalprice,
        o2.o_orderstatus,
        oc.OrderLevel + 1
    FROM orders o2
    JOIN OrderCTE oc ON o2.o_orderkey = oc.o_orderkey + 1
),
SupplierStats AS (
    SELECT 
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        COUNT(DISTINCT ps.ps_partkey) AS UniquePartsSupplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_nationkey
),
OrderDetail AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalPrice,
        COUNT(l.l_orderkey) AS LineCount,
        RANK() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS PriceRank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)

SELECT 
    r.r_name AS Region,
    SUM(oss.TotalPrice) AS AggregateOrderTotal,
    COUNT(DISTINCT oss.o_orderkey) AS DistinctOrderCount,
    ss.TotalSupplyCost,
    ss.UniquePartsSupplied
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierStats ss ON s.s_nationkey = ss.s_nationkey
LEFT JOIN OrderDetail oss ON ss.UniquePartsSupplied = oss.LineCount
WHERE ss.TotalSupplyCost IS NOT NULL
GROUP BY r.r_name, ss.TotalSupplyCost, ss.UniquePartsSupplied
HAVING SUM(oss.TotalPrice) > 10000
ORDER BY AggregateOrderTotal DESC;
