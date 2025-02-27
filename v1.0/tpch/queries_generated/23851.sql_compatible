
WITH RECURSIVE ranked_orders AS (
    SELECT o.o_orderkey,
           o.o_orderstatus,
           o.o_totalprice,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1998-10-01' - INTERVAL '1 year'
),
supplier_performance AS (
    SELECT s.s_suppkey,
           COUNT(DISTINCT ps.ps_partkey) AS part_count,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
customer_orders AS (
    SELECT c.c_custkey,
           c.c_name,
           COUNT(o.o_orderkey) AS total_orders,
           COALESCE(SUM(o.o_totalprice), 0) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
lineitem_summary AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_revenue,
           AVG(l.l_quantity) AS avg_line_quantity,
           MAX(l.l_tax) AS max_tax
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT r.o_orderkey,
       r.o_orderstatus,
       r.o_totalprice,
       sp.part_count,
       co.total_orders,
       co.total_spent,
       ls.total_line_revenue,
       ls.avg_line_quantity,
       CASE
           WHEN r.rank > 10 THEN 'Marginal'
           WHEN r.rank BETWEEN 4 AND 10 THEN 'Average'
           ELSE 'Exceptional'
       END AS order_rank_category,
       CASE 
           WHEN ls.max_tax IS NULL THEN 'No Tax Data'
           ELSE 'Has Tax Data'
       END AS tax_data_present
FROM ranked_orders r
LEFT JOIN supplier_performance sp ON r.o_orderkey IN (SELECT DISTINCT l.l_orderkey FROM lineitem l WHERE l.l_orderkey IS NOT NULL)
LEFT JOIN customer_orders co ON co.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA'))
LEFT JOIN lineitem_summary ls ON ls.l_orderkey = r.o_orderkey
WHERE r.o_totalprice > (SELECT AVG(o.o_totalprice) FROM orders o)
  AND EXISTS (SELECT 1 FROM customer c WHERE c.c_acctbal > ALL (SELECT DISTINCT s.s_acctbal FROM supplier s WHERE s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')))
ORDER BY r.o_orderkey DESC, co.total_spent ASC
LIMIT 50;
