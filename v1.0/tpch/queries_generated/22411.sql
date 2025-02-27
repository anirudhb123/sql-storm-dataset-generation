WITH RECURSIVE SupplierChain AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS Level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sc.Level + 1
    FROM partsupp ps
    JOIN SupplierChain sc ON ps.ps_suppkey = sc.s_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE ps.ps_availqty > 0 AND sc.Level < 5
), 

RegionStats AS (
    SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) AS NationCount, SUM(s.s_acctbal) AS TotalSupplierBalance
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
),

CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),

ComplicatedLineItem AS (
    SELECT l.l_orderkey, l.l_partkey, 
           CASE 
               WHEN l.l_discount IS NULL THEN 0 
               ELSE (l.l_extendedprice * (1 - l.l_discount)) 
           END AS EffectivePrice,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber DESC) AS rn
    FROM lineitem l
    WHERE l.l_shipdate >= '2023-01-01'
),

FinalStats AS (
    SELECT 
        rs.r_name,
        cs.c_name,
        S.s_name,
        COUNT(DISTINCT OrderKey) AS TotalOrders, 
        SUM(CASE WHEN l.rn = 1 THEN EffectivePrice ELSE 0 END) AS MaxLineItemPrice,
        AVG(s.s_acctbal) AS AvgSupplierBalance,
        COUNT(DISTINCT n.n_nationkey) FILTER (WHERE cs.TotalSpent > 1000) AS VIPCustomers
    FROM RegionStats rs
    JOIN CustomerOrders cs ON rs.NationCount > 5
    LEFT JOIN SupplierChain s ON s.Level = 0
    JOIN ComplicatedLineItem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderdate >= '2023-01-01')
    LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY rs.r_name, cs.c_name, S.s_name
)

SELECT r_name, c_name, s_name, TotalOrders, MaxLineItemPrice, AvgSupplierBalance, VIPCustomers
FROM FinalStats
WHERE TotalOrders > 10 AND AvgSupplierBalance > (SELECT AVG(s_acctbal) FROM supplier) 
ORDER BY VIPCustomers DESC, MaxLineItemPrice DESC;
