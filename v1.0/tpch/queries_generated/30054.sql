WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.n_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_availqty > 10)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_address, s.n_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN supplier_hierarchy sh ON s.n_nationkey = sh.n_nationkey
    WHERE sh.level < 5
),
order_summary AS (
    SELECT o.o_orderkey, o.o_orderstatus, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2022-12-31'
    GROUP BY o.o_orderkey, o.o_orderstatus
),
nation_revenue AS (
    SELECT n.n_name, SUM(os.total_revenue) AS total_revenue
    FROM nation n
    LEFT JOIN (
        SELECT o.c_custkey, s.n_nationkey, os.total_revenue
        FROM order_summary os
        JOIN customer c ON os.o_orderkey = c.c_custkey
        JOIN supplier s ON c.c_nationkey = s.n_nationkey
    ) AS os ON n.n_nationkey = os.n_nationkey
    GROUP BY n.n_name
),
part_pricing AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
)
SELECT nh.n_name, 
       COALESCE(nr.total_revenue, 0) AS total_revenue, 
       pp.p_name, 
       pp.p_retailprice, 
       pp.avg_supplycost,
       CASE
           WHEN (pp.p_retailprice > pp.avg_supplycost * 1.2) THEN 'High Margin'
           WHEN (pp.p_retailprice IS NULL OR pp.avg_supplycost IS NULL) THEN 'Price Info Missing'
           ELSE 'Normal Margin'
       END AS pricing_strategy
FROM nation_revenue nr
FULL OUTER JOIN part_pricing pp ON pp.p_retailprice > 0
LEFT JOIN nation nh ON nh.n_nationkey = nr.n_nationkey
WHERE nr.total_revenue > 50000 OR pp.p_retailprice > 100
ORDER BY total_revenue DESC, pp.p_name ASC;
