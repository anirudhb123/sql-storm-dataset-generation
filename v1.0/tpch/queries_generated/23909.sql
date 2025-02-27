WITH RECURSIVE size_hierarchy AS (
    SELECT p_partkey, p_size, 1 AS level
    FROM part
    WHERE p_size IS NOT NULL
    UNION ALL
    SELECT p.partkey, p.p_size, sh.level + 1
    FROM size_hierarchy sh
    JOIN part p ON sh.p_size = p.p_size - 1
),
supplier_details AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (
        SELECT AVG(s1.s_acctbal)
        FROM supplier s1
        WHERE s1.s_nationkey = s.s_nationkey
    )
),
customer_summary AS (
    SELECT c.c_custkey, 
           SUM(o.o_totalprice) AS total_spent,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY c.c_custkey
    HAVING SUM(o.o_totalprice) > 1000
),
lineitem_summary AS (
    SELECT l.l_partkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
    GROUP BY l.l_partkey
)
SELECT p.p_partkey, p.p_name, sh.level AS size_level, 
       COALESCE(sd.rank, 'N/A') AS top_supplier_rank,
       cs.total_spent,
       ls.total_revenue
FROM part p
LEFT JOIN size_hierarchy sh ON p.p_partkey = sh.p_partkey
LEFT JOIN supplier_details sd ON p.p_partkey IN (
    SELECT ps.ps_partkey
    FROM partsupp ps
    WHERE ps.ps_supplycost <= (
        SELECT MAX(ps1.ps_supplycost) FROM partsupp ps1 WHERE ps1.ps_partkey = p.p_partkey
    )
)
LEFT JOIN customer_summary cs ON p.p_partkey IN (
    SELECT l.l_partkey
    FROM lineitem l
    WHERE l.l_orderkey IN (
        SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O'
    )
)
LEFT JOIN lineitem_summary ls ON p.p_partkey = ls.l_partkey
WHERE p.p_retailprice IS NOT NULL
  AND EXISTS (
      SELECT 1
      FROM region r
      WHERE r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey IN (
          SELECT c.c_nationkey FROM customer c WHERE c.c_custkey IN (
              SELECT o.o_custkey FROM orders o
          )
      ) LIMIT 1)
  )
ORDER BY p.p_partkey, size_level DESC NULLS LAST, total_spent DESC;
