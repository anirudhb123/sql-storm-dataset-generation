WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
PartSupplierSummary AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_availqty, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
CustomerSpend AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    COALESCE(ps.total_availqty, 0) AS total_availqty,
    COALESCE(ps.avg_supplycost, 0) AS avg_supplycost,
    cs.total_spent,
    s.s_name AS high_balance_supplier
FROM part p
LEFT JOIN PartSupplierSummary ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN CustomerSpend cs ON cs.c_custkey IN (
    SELECT c.c_custkey
    FROM customer c
    WHERE c.c_acctbal > 1000 
)
LEFT JOIN supplier s ON s.s_suppkey = (SELECT MIN(s2.s_suppkey) FROM supplier s2 WHERE s2.s_acctbal = (
    SELECT MAX(s3.s_acctbal) FROM supplier s3
) AND s2.s_nationkey = p.p_partkey % 5)
WHERE p.p_size > 10
ORDER BY p.p_brand DESC, total_availqty ASC;
