WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_comment, 
           ROW_NUMBER() OVER (PARTITION BY s_suppkey ORDER BY s_name) AS rn
    FROM supplier 
    WHERE s_acctbal IS NOT NULL 
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_comment,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY s.s_name)
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.rn < 10
),
HighestSpender AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 
           NTILE(5) OVER (ORDER BY c.c_acctbal DESC) AS spender_level
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           COALESCE(SUM(ps.ps_supplycost), 0) AS total_supplycost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
)
SELECT 
    r.r_name, 
    n.n_name, 
    s.s_name AS supplier_name, 
    p.p_name AS part_name, 
    p.total_supplycost, 
    h.spender_level,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN lineitem l ON s.s_suppkey = l.l_suppkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN PartDetails p ON l.l_partkey = p.p_partkey
JOIN HighestSpender h ON o.o_custkey = h.c_custkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
  AND h.spender_level IS NOT NULL
GROUP BY r.r_name, n.n_name, s.s_name, p.p_name, p.total_supplycost, h.spender_level
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY avg_price DESC, total_supplycost DESC
LIMIT 50 OFFSET 10;
