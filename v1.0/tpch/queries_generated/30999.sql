WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           1 AS hierarchy_level
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s_acctbal) FROM supplier
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           sh.hierarchy_level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.hierarchy_level < 5
),
PartSupplier AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_availqty,
           AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT 
    p.p_name,
    p.p_brand,
    ps.total_availqty,
    ps.avg_supplycost,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    RANK() OVER (PARTITION BY p.p_brand ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS price_rank,
    CASE 
        WHEN r.r_name IS NULL THEN 'Unknown Region' 
        ELSE r.r_name 
    END AS region_name
FROM part p
LEFT JOIN PartSupplier ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN orders o ON o.o_orderkey = l.l_orderkey
LEFT JOIN supplier s ON s.s_suppkey = l.l_suppkey
LEFT JOIN nation n ON n.n_nationkey = s.s_nationkey
LEFT JOIN region r ON r.r_regionkey = n.n_regionkey
WHERE p.p_size > 25 AND 
      (l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31')
      AND l.l_returnflag = 'N'
GROUP BY p.p_partkey, p.p_name, p.p_brand, ps.total_availqty, r.r_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 500000
ORDER BY price_rank, total_availqty DESC;
