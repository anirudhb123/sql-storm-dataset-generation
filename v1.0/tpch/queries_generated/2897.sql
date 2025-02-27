WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS NetSales,
        COUNT(DISTINCT l.l_linenumber) AS LineCount
    FROM lineitem l
    WHERE l.l_shipdate < CURRENT_DATE
    GROUP BY l.l_orderkey
),
NationalStats AS (
    SELECT
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS UniqueCustomers,
        SUM(lo.NetSales) AS TotalNetSales
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN LineItemSummary lo ON o.o_orderkey = lo.l_orderkey
    GROUP BY n.n_name
)
SELECT 
    rs.s_name AS SupplierName,
    ns.n_name AS NationName,
    ns.UniqueCustomers,
    ns.TotalNetSales,
    rs.TotalSupplyCost
FROM RankedSuppliers rs
JOIN NationalStats ns ON rs.s_nationkey = ns.n_nationkey
WHERE rs.rank = 1
  AND ns.TotalNetSales > (SELECT AVG(TotalNetSales) FROM NationalStats)
ORDER BY ns.TotalNetSales DESC, rs.TotalSupplyCost DESC;
