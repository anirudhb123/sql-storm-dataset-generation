WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 1 AS depth
    FROM supplier
    WHERE s_acctbal IS NOT NULL AND s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) -- only suppliers with above average account balance
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.depth + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey AND sh.depth < 5 -- limit depth to 5 levels
)
, part_sales AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31' -- filter for the current year
    GROUP BY p.p_partkey, p.p_name
), ranked_parts AS (
    SELECT p.*, RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM part_sales p
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_quantity,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_phone, ')'), '; ') AS supplier_contact_details,
    (SELECT COUNT(*) FROM lineitem l2 WHERE l2.l_tax IS NULL OR l2.l_tax < 0) AS null_or_negative_tax_count
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier_hierarchy sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
WHERE EXISTS (
    SELECT 1
    FROM ranked_parts rp
    WHERE rp.sales_rank <= 10 AND l.l_shipdate >= CURRENT_DATE - INTERVAL '30 days'
)
GROUP BY r.r_name
HAVING SUM(ps.ps_availqty) > 0
ORDER BY customer_count DESC, total_supply_cost DESC;
