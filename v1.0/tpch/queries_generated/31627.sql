WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, 1 AS Level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT ss.s_suppkey, ss.s_name, sh.Level + 1
    FROM supplier ss
    JOIN SupplierHierarchy sh ON ss.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    WHERE ss.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),

PartWithHighDemand AS (
    SELECT ps.ps_partkey, SUM(l.l_quantity) AS TotalQuantity
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_partkey
    HAVING SUM(l.l_quantity) > 1000
),

CustomerOrderSummary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS OrderCount, SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)

SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    COALESCE(ph.TotalQuantity, 0) AS HighDemandQty,
    ROUND(COALESCE(cs.TotalSpent, 0) / NULLIF(cs.OrderCount, 0), 2) AS AvgSpentPerOrder,
    sh.Level AS SupplierLevel
FROM 
    part p
LEFT JOIN PartWithHighDemand ph ON p.p_partkey = ph.ps_partkey
LEFT JOIN CustomerOrderSummary cs ON cs.OrderCount > 0
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = (SELECT MIN(ps.ps_suppkey) FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey)
WHERE 
    p.p_size BETWEEN 1 AND 20
ORDER BY 
    p.p_partkey;
