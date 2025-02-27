WITH RECURSIVE region_nations AS (
    SELECT r.r_regionkey, r.r_name, n.n_nationkey, n.n_name, n.n_comment
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    UNION ALL
    SELECT rn.r_regionkey, rn.r_name, n.n_nationkey, n.n_name, n.n_comment
    FROM region_nations rn
    JOIN nation n ON rn.r_name LIKE CONCAT('%', n.n_name, '%') AND rn.n_name != n.n_name
),
max_customer_spending AS (
    SELECT c.c_custkey, c.c_name, MAX(o.o_totalprice) AS max_spending
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
supplier_part_count AS (
    SELECT ps.ps_suppkey, COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
),
total_revenue AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    rn.r_name AS region_name,
    COUNT(DISTINCT cs.c_custkey) AS total_customers,
    COALESCE(MAX(mcs.max_spending), 0) AS highest_customer_spending,
    COALESCE(SUM(su.part_count), 0) AS total_parts_supplied,
    COALESCE(SUM(tr.revenue), 0) AS total_revenue_generated
FROM region_nations rn
LEFT JOIN max_customer_spending mcs ON rn.n_nationkey = mcs.c_custkey
LEFT JOIN supplier_part_count su ON rn.r_regionkey = (SELECT s.n_nationkey FROM supplier s WHERE s.s_suppkey = su.ps_suppkey)
LEFT JOIN total_revenue tr ON rn.n_nationkey = (SELECT c.c_custkey FROM customer c WHERE c.c_custkey = mcs.c_custkey)
WHERE rn.n_name IS NOT NULL
GROUP BY rn.r_regionkey, rn.r_name
HAVING COUNT(DISTINCT cs.c_custkey) > 5 OR MAX(mcs.max_spending) > 10000
ORDER BY total_revenue_generated DESC NULLS LAST;
