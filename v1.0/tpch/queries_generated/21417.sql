WITH ranked_suppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL
),
filtered_parts AS (
    SELECT p.p_partkey,
           p.p_name,
           p.p_retailprice,
           CASE WHEN p.p_size > 100 THEN 'LARGE' ELSE 'SMALL' END AS size_category
    FROM part p
    WHERE p.p_retailprice BETWEEN 50 AND 100
),
distinct_orders AS (
    SELECT DISTINCT o.o_orderkey, 
           o.o_orderdate, 
           CASE WHEN o.o_orderstatus = 'F' THEN 'Completed' ELSE 'Pending' END AS order_status
    FROM orders o
),
total_revenue AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total
    FROM lineitem l
    WHERE l.l_shipdate >= '2023-01-01'
    GROUP BY l.l_orderkey
)
SELECT n.n_name,
       r.r_name,
       SUM(t.total) AS revenue,
       COUNT(DISTINCT o.o_orderkey) AS order_count,
       STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', p.p_retailprice, ')') ORDER BY p.p_retailprice DESC) AS part_details
FROM nation n
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN filtered_parts p ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost <= 20)
LEFT JOIN ranked_suppliers rs ON p.p_partkey = rs.s_suppkey AND rs.rnk = 1
LEFT JOIN total_revenue t ON t.l_orderkey = o.o_orderkey
LEFT JOIN distinct_orders o ON t.l_orderkey = o.o_orderkey
GROUP BY n.n_name, r.r_name
HAVING SUM(t.total) > 1000 AND COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY revenue DESC, n.n_name, r.r_name;
