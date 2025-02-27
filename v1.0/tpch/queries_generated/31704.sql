WITH RECURSIVE cust_orders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) IS NOT NULL
),
supplier_ranked AS (
    SELECT s.s_suppkey, s.s_name, ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),
part_details AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
filtered_orders AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice, p.p_partkey, p.p_name, l.*
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN part_details p ON l.l_partkey = p.p_partkey
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '30 days'
      AND l.l_discount > 0.05
)
SELECT 
    r.r_name AS region,
    SUM(COALESCE(f.o_totalprice, 0)) AS total_revenue,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    AVG(CASE WHEN f.l_returnflag = 'R' THEN f.l_extendedprice ELSE NULL END) AS avg_return_price
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier_ranked sr ON n.n_nationkey = sr.s_nationkey
LEFT JOIN filtered_orders f ON sr.s_suppkey = f.l_suppkey
LEFT JOIN cust_orders c ON f.o_orderkey = c.c_custkey
WHERE sr.rank <= 5
GROUP BY r.r_name
ORDER BY total_revenue DESC, unique_customers DESC;
