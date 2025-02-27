WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS RankWithinNation
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
        SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
Nations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS RegionName
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
OrderDetailSummary AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_linenumber) AS LineItemCount,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS Revenue,
        AVG(l.l_tax) as AvgTaxRate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY o.o_orderkey
)
SELECT 
    n.NationName,
    n.RegionName,
    cs.c_custkey,
    cs.TotalOrders,
    cs.TotalSpent,
    rs.TotalSupplyCost,
    ods.LineItemCount,
    ods.Revenue,
    COALESCE(ods.AvgTaxRate, 0) AS AvgTaxRate,
    CASE 
        WHEN cs.TotalSpent IS NULL THEN 'No Orders'
        WHEN cs.TotalSpent < 1000 THEN 'Low Spend'
        WHEN cs.TotalSpent BETWEEN 1000 AND 5000 THEN 'Moderate Spend'
        ELSE 'High Spend'
    END AS SpendCategory
FROM Nations n
LEFT JOIN CustomerOrders cs ON n.n_nationkey = cs.c_custkey -- Potential mistake: Joining on customer key instead of nation key
LEFT JOIN RankedSuppliers rs ON n.n_nationkey = rs.s_suppkey -- Logical mistake: Outer join on supplier key
LEFT JOIN OrderDetailSummary ods ON cs.c_custkey = ods.o_orderkey -- Unusual join, linking customer to orders
WHERE rs.RankWithinNation <= 5 OR cs.TotalOrders IS NOT NULL
ORDER BY n.RegionName, cs.TotalSpent DESC NULLS LAST;
