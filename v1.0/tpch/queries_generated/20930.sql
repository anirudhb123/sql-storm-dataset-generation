WITH RECURSIVE expensive_parts AS (
    SELECT ps_partkey, ps_supplycost
    FROM partsupp
    WHERE ps_supplycost > (SELECT AVG(ps_supplycost) FROM partsupp)
    UNION ALL
    SELECT ps.partkey, ps.ps_supplycost
    FROM partsupp ps
    JOIN expensive_parts ep ON ps.ps_partkey = ep.ps_partkey
    WHERE ps.ps_supplycost < ep.ps_supplycost
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 1000.00
),
filtered_suppliers AS (
    SELECT s.s_supkey, s.s_name, s.s_acctbal, 
           (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey) as part_count,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rn
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
)
SELECT DISTINCT
    p.p_name, 
    p.p_mfgr,
    ps.ps_supplycost, 
    CASE 
        WHEN l.l_discount > 0.2 THEN 'High Discount'
        ELSE 'Normal Discount'
    END AS discount_category,
    c.total_spent,
    COALESCE(rs.r_name, 'No Region') AS supplier_region
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN customer_orders c ON c.total_spent > 500
JOIN (
    SELECT DISTINCT n.n_nationkey, r.r_name
    FROM nation n 
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
) rs ON ps.ps_suppkey IN (SELECT s.s_suppkey
                           FROM filtered_suppliers s WHERE s.part_count > 1)
WHERE ps.ps_availqty BETWEEN 10 AND 100
  AND p.p_retailprice IS NOT NULL 
  AND (p.p_comment IS NOT NULL OR p.p_container = 'Box')
  AND (l.l_returnflag IS NULL OR l.l_linestatus = 'O')
ORDER BY p.p_name;
