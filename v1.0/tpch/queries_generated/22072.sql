WITH RECURSIVE relevant_suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    INNER JOIN relevant_suppliers rs ON s.s_suppkey = rs.s_suppkey - 1
),
part_region_summary AS (
    SELECT p.p_partkey, p.p_name, r.r_name, SUM(ps.ps_availqty) AS total_avail_qty, 
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE p.p_size IS NOT NULL AND p.p_size > 0
    GROUP BY p.p_partkey, p.p_name, r.r_name
),
large_order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '1995-01-01' AND '1995-12-31'
    GROUP BY o.o_orderkey
)
SELECT prs.p_name, prs.total_avail_qty, ro.total_revenue, s.s_name
FROM part_region_summary prs
FULL OUTER JOIN large_order_summary ro ON prs.total_avail_qty > 0
LEFT JOIN relevant_suppliers s ON prs.total_avail_qty < s.s_acctbal AND prs.supplier_count > 1
WHERE prs.r_name IS NOT NULL OR (ro.total_revenue IS NULL AND prs.total_avail_qty BETWEEN 50 AND 100)
ORDER BY prs.total_avail_qty DESC, ro.total_revenue DESC, s.s_name
LIMIT 10
OFFSET 5;
