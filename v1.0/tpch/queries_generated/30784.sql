WITH RECURSIVE PopularSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ps.ps_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_shipdate >= DATE '2023-01-01'
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
RankedSuppliers AS (
    SELECT s.*, RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM PopularSuppliers s
)
SELECT 
    DISTINCT r.r_name,
    COALESCE(SUM(o.o_totalprice), 0) AS total_order_value,
    AVG(CASE WHEN c.c_acctbal IS NULL THEN 0 ELSE c.c_acctbal END) AS avg_customer_balance,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN customer c ON s.s_suppkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey AND o.o_orderstatus = 'F'
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name
HAVING COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY total_order_value DESC
LIMIT 10;
