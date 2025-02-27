WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size BETWEEN 1 AND 10
),
CustomerOrders AS (
    SELECT c.c_custkey, o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, o.o_orderkey
),
RevenueByNation AS (
    SELECT n.n_nationkey, SUM(co.total_revenue) AS total_revenue
    FROM nation n
    JOIN CustomerOrders co ON co.c_custkey IN (
        SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey
    )
    GROUP BY n.n_nationkey
)
SELECT r.r_name, 
       COALESCE(rb.total_revenue, 0) AS revenue, 
       COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
       p.p_name,
       p.p_retailprice
FROM region r
LEFT JOIN RevenueByNation rb ON r.r_regionkey = rb.n_nationkey
LEFT JOIN FilteredParts p ON p.p_partkey IN (
    SELECT ps.ps_partkey FROM partsupp ps
    WHERE ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
)
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = r.r_regionkey
GROUP BY r.r_name, rb.total_revenue, p.p_name, p.p_retailprice
HAVING COUNT(DISTINCT sh.s_suppkey) > 0
ORDER BY revenue DESC, supplier_count DESC, p.p_retailprice DESC;
