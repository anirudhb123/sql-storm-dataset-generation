WITH RECURSIVE SupplyChain AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ps.ps_availqty, 
        ps.ps_supplycost,
        1 AS Level
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 100

    UNION ALL

    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ps.ps_availqty,
        ps.ps_supplycost,
        sc.Level + 1
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN SupplyChain sc ON ps.ps_partkey = sc.s_suppkey
    WHERE ps.ps_availqty > 100
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        COUNT(DISTINCT l.l_orderkey) AS TotalLineItems,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS RevenueRank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
SupplierRegions AS (
    SELECT 
        n.n_name AS Nation,
        r.r_name AS Region,
        SUM(s.s_acctbal) AS TotalAcctBal
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_name, r.r_name
)
SELECT 
    sr.Nation,
    sr.Region,
    sr.TotalAcctBal,
    os.TotalRevenue,
    os.TotalLineItems,
    sc.s_name AS SupplierName,
    sc.ps_availqty AS AvailableQuantity,
    COALESCE(sc.ps_supplycost, 0) AS SupplyCost
FROM SupplierRegions sr
LEFT JOIN OrderStats os ON sr.Region = os.o_orderstatus 
LEFT JOIN SupplyChain sc ON sr.Nation = sc.s_name
WHERE sr.TotalAcctBal > 1000
  AND os.RevenueRank <= 10
ORDER BY sr.TotalAcctBal DESC, os.TotalRevenue DESC;
