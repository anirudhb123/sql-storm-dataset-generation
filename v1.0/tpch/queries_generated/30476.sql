WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_comment, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_comment, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
PartSupplierStats AS (
    SELECT ps.ps_partkey, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           SUM(ps.ps_availqty) AS total_availqty, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
OrderStats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           MAX(o.o_orderdate) AS last_order_date
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
CustomerOrderCounts AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT n.n_name, p.p_name,
       COALESCE(co.order_count, 0) AS order_count,
       COALESCE(co.total_spent, 0) AS total_spent,
       ps.supplier_count, ps.total_availqty, ps.avg_supplycost,
       sh.level AS supplier_level,
       ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY total_spent DESC) AS revenue_rank
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN PartSupplierStats ps ON ps.ps_partkey = (SELECT p.p_partkey
                                               FROM part p
                                               WHERE p.p_brand = s.s_name
                                               ORDER BY p.p_retailprice DESC
                                               LIMIT 1)
LEFT JOIN CustomerOrderCounts co ON co.c_custkey = (SELECT c.c_custkey
                                                     FROM customer c
                                                     WHERE c.c_nationkey = n.n_nationkey
                                                     ORDER BY c.c_acctbal DESC
                                                     LIMIT 1)
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
WHERE (ps.total_availqty IS NOT NULL OR ps.avg_supplycost IS NULL)
  AND sh.level <= 3
ORDER BY n.n_name, supplier_count DESC, order_count DESC;
