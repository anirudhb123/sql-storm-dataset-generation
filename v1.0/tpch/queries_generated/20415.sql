WITH RECURSIVE supplier_tree AS (
    SELECT s_suppkey, s_name, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL
    UNION ALL
    SELECT sp.s_suppkey, sp.s_name, sp.s_nationkey, st.level + 1
    FROM supplier sp
    JOIN supplier_tree st ON sp.s_nationkey = st.s_nationkey
    WHERE st.level < 3
),
part_summary AS (
    SELECT p.p_partkey, 
           p.p_name,
           SUM(ps.ps_availqty) AS total_available_qty,
           ROUND(AVG(ps.ps_supplycost), 2) AS avg_supply_cost,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
top_customers AS (
    SELECT c.c_custkey, 
           c.c_name,
           ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > (
        SELECT AVG(c2.c_acctbal) 
        FROM customer c2 
        WHERE c2.c_mktsegment = c.c_mktsegment
    )
    GROUP BY c.c_custkey, c.c_name, c.c_mktsegment
),
frequent_part_suppliers AS (
    SELECT ps.p_partkey, 
           ps.ps_suppkey, 
           COUNT(*) AS freq
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.p_partkey, ps.ps_suppkey
    HAVING COUNT(*) > 5
)
SELECT 
    pt.p_name AS part_name,
    COALESCE(CAST(SUM(CASE WHEN l.l_shipdate < l.l_commitdate THEN l.l_extendedprice ELSE 0 END) AS DECIMAL(12, 2)), 0) AS lost_revenue,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    ROW_NUMBER() OVER (PARTITION BY pt.p_partkey ORDER BY lost_revenue DESC) AS supplier_revenue_rank
FROM part_summary pt
LEFT JOIN frequent_part_suppliers fps ON pt.p_partkey = fps.p_partkey
LEFT JOIN supplier s ON fps.ps_suppkey = s.s_suppkey
LEFT JOIN top_customers c ON s.s_nationkey = c.c_custkey
WHERE pt.total_available_qty IS NOT NULL 
  AND pt.supplier_count > 1
  AND NOT EXISTS (
      SELECT 1 
      FROM lineitem l 
      WHERE l.l_orderkey IN (
          SELECT o.o_orderkey 
          FROM orders o 
          WHERE o.o_orderstatus = 'F'
      ) 
      AND l.l_partkey = pt.p_partkey
  )
GROUP BY pt.p_name, s.s_name, c.c_name
ORDER BY pt.p_name, lost_revenue DESC
LIMIT 100;
