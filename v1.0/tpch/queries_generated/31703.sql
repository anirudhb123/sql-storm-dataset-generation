WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_orderkey
    WHERE o.o_orderstatus = 'O'
),
SupplierStats AS (
    SELECT ps.ps_suppkey, SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
),
LineItemDetails AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM lineitem l
    GROUP BY l.l_orderkey
),
CustomerSummary AS (
    SELECT c.c_custkey, c.c_name,
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent,
           MAX(o.o_orderdate) AS last_order
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 0
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 1000
)
SELECT c.c_name,
       COALESCE(l.total_revenue, 0) AS total_revenue,
       COALESCE(ss.total_available, 0) AS total_available,
       c.order_count,
       c.total_spent,
       oh.level AS order_hierarchy_level
FROM CustomerSummary c
LEFT JOIN LineItemDetails l ON c.c_custkey = l.l_orderkey
LEFT JOIN SupplierStats ss ON l.l_orderkey = ss.ps_suppkey
JOIN OrderHierarchy oh ON c.order_count > 1
WHERE c.last_order > CURRENT_DATE - INTERVAL '1 year'
  AND c.total_spent < (SELECT AVG(total_spent) FROM CustomerSummary)
ORDER BY c.total_spent DESC, total_revenue DESC;
