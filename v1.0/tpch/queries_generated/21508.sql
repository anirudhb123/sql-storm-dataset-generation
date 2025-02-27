WITH RECURSIVE customer_hierarchy AS (
    SELECT c_custkey, c_name, c_nationkey, 0 AS level
    FROM customer
    WHERE c_custkey = (SELECT MIN(c_custkey) FROM customer)
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE ch.level < 5
),
part_supplier_summary AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available, AVG(ps.ps_supplycost) AS avg_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
lineitem_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           MAX(l.l_discount) AS max_discount_applied
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND CURRENT_DATE
    GROUP BY l.l_orderkey
)
SELECT 
    d.r_name AS region_name,
    p.p_name AS part_name,
    CTE.c_name AS customer_name,
    COALESCE(sum(ls.total_revenue), 0) AS total_revenue_generated,
    COALESCE(s.total_available, 0) AS total_available_parts,
    STRING_AGG(DISTINCT s.s_comment, ', ') AS supplier_comments,
    ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(ls.total_revenue) DESC) AS revenue_rank
FROM customer_hierarchy CTE
JOIN nation n ON CTE.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN partsupp ps ON ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 10)
JOIN part_supplier_summary s ON ps.ps_partkey = s.ps_partkey
LEFT JOIN (
    SELECT lo.l_orderkey, SUM(lo.l_extendedprice) AS total_locked_revenue
    FROM lineitem lo
    WHERE lo.l_returnflag = 'R'
    GROUP BY lo.l_orderkey
) lr ON lr.l_orderkey = ANY (SELECT l.l_orderkey FROM lineitem l WHERE l.l_suppkey = ps.ps_suppkey)
LEFT JOIN lineitem_summary ls ON ls.l_orderkey = (SELECT o.o_orderkey FROM orders o 
                                                   WHERE o.o_custkey = CTE.c_custkey 
                                                   AND o.o_orderstatus <> 'O' 
                                                   LIMIT 1)
WHERE SUM(ls.total_revenue) > (SELECT AVG(total_revenue) FROM lineitem_summary)
AND r.r_name IS NOT NULL
GROUP BY r.r_regionkey, p.p_name, CTE.c_name
HAVING COUNT(DISTINCT n.n_nationkey) > 1
ORDER BY region_name, revenue_rank;
