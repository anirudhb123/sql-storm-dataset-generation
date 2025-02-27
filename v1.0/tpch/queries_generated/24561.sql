WITH ranked_orders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderdate >= '1998-01-01'
      AND o.o_orderdate < '1999-01-01'
),
supplier_summary AS (
    SELECT s.s_nationkey,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    GROUP BY s.s_nationkey
),
filtered_nations AS (
    SELECT n.n_nationkey,
           n.n_name,
           r.r_name,
           ss.total_cost,
           ss.supplier_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier_summary ss ON n.n_nationkey = ss.s_nationkey
    WHERE r.r_name NOT LIKE '%east%'
      AND (ss.total_cost IS NOT NULL OR ss.supplier_count > 0)
)
SELECT fo.o_orderkey,
       fn.n_name AS nation_name,
       COALESCE(r.price_rank, 0) AS order_price_rank,
       fn.total_cost,
       fn.supplier_count,
       CASE 
           WHEN fn.total_cost IS NULL THEN 'No Costs Recorded'
           WHEN fn.supplier_count = 0 THEN 'No Suppliers'
           ELSE 'Active'
       END AS supplier_status
FROM ranked_orders r
RIGHT JOIN orders o ON r.o_orderkey = o.o_orderkey
JOIN filtered_nations fn ON o.o_custkey IN (
    SELECT c.c_custkey
    FROM customer c
    WHERE c.c_nationkey = fn.n_nationkey
)
WHERE o.o_orderstatus IN ('O', 'F')
  AND (fn.total_cost IS NOT NULL OR o.o_totalprice > 500.00)
ORDER BY fn.n_name, r.o_orderkey;
