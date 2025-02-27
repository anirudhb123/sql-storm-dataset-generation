WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS Level
    FROM supplier s
    WHERE s.s_acctbal >= (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.Level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'Germany') 
    WHERE sh.Level < 3
),
RankedCustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSpent,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS SpendingRank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
    HAVING SUM(o.o_totalprice) > 1000
),
PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        MAX(ps.ps_availqty) AS MaxAvailable
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING TotalCost > (SELECT AVG(ps_supplycost * ps_availqty) FROM partsupp)
)
SELECT 
    r.r_name AS RegionName,
    c.c_name AS CustomerName,
    COALESCE(po.TotalSpent, 0) AS CustomerTotalSpent,
    COALESCE(ph.TotalCost, 0) AS PartsTotalCost,
    sh.Level AS SupplierLevel
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN RankedCustomerOrders po ON c.c_custkey = po.c_custkey
LEFT JOIN PartSupplierDetails ph ON ph.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT sh.s_suppkey FROM SupplierHierarchy sh))
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = (SELECT MIN(s.s_suppkey) FROM supplier s WHERE s.s_nationkey = n.n_nationkey)
WHERE c.c_acctbal IS NOT NULL
ORDER BY r.r_name, c.c_name;
