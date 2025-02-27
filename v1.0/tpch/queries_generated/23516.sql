WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS HierarchyLevel
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.HierarchyLevel + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.HierarchyLevel < 5 AND s.s_suppkey != sh.s_suppkey
),
TotalOrderValue AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalValue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_totalprice > 1000
    GROUP BY o.o_orderkey
),
NationStats AS (
    SELECT 
        n.n_name, 
        COUNT(DISTINCT s.s_suppkey) AS SupplierCount,
        AVG(s.s_acctbal) AS AvgAccountBalance,
        MAX(s.s_acctbal) AS MaxAccountBalance
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
PartCustomerSummary AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_quantity) AS TotalQuantity,
        COUNT(DISTINCT p.p_partkey) AS DistinctParts,
        SUM(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice ELSE 0 END) AS TotalDiscountedPrice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY c.c_custkey
)
SELECT 
    r.r_name,
    n.SupplierCount,
    n.AvgAccountBalance,
    n.MaxAccountBalance,
    pcs.TotalQuantity,
    pcs.DistinctParts,
    pcs.TotalDiscountedPrice,
    sh.HierarchyLevel
FROM region r
JOIN NationStats n ON n.n_nationkey = r.r_regionkey
FULL OUTER JOIN PartCustomerSummary pcs ON pcs.TotalQuantity > 0
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = n.n_nationkey
WHERE n.SupplierCount > 10 OR pcs.DistinctParts IS NOT NULL
ORDER BY r.r_name, TotalDiscountedPrice DESC NULLS LAST
LIMIT 100;
