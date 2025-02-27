WITH RECURSIVE cte_orders AS (
    SELECT o_orderkey, o_custkey, o_orderstatus, o_orderdate, o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_orderdate) AS rn
    FROM orders 
    WHERE o_orderdate >= '2023-01-01'
),
cte_supplier AS (
    SELECT ps_supplycost, ps_availqty,
           ROW_NUMBER() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost ASC) AS rn
    FROM partsupp
    WHERE ps_availqty > (
        SELECT AVG(ps_availqty) FROM partsupp
    )
),
cte_customer AS (
    SELECT c_custkey, c_name, c_acctbal,
           LEAD(c_acctbal) OVER (ORDER BY c_custkey) AS next_acctbal
    FROM customer
),
cte_lineitem AS (
    SELECT l_orderkey, SUM(l_extendedprice * (1 - l_discount)) AS total_sales,
           COUNT(l_linenumber) AS line_count
    FROM lineitem
    GROUP BY l_orderkey
),
combined AS (
    SELECT co.o_orderkey, co.o_orderstatus, c.c_name, co.o_totalprice,
           li.total_sales, li.line_count, s.ps_supplycost, s.ps_availqty
    FROM cte_orders co
    LEFT OUTER JOIN cte_lineitem li ON co.o_orderkey = li.l_orderkey
    JOIN cte_customer c ON c.c_custkey = co.o_custkey
    LEFT JOIN cte_supplier s ON li.total_sales > s.ps_supplycost
    WHERE co.rn = 1 AND c.next_acctbal IS NOT NULL
)
SELECT r.r_name, AVG(c_total.total_sales) AS avg_total_sales, 
       SUM(CASE WHEN c_total.total_sales > 1000 THEN 1 ELSE 0 END) AS high_volume_orders
FROM combined c_total
JOIN nation n ON c_total.o_custkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
GROUP BY r.r_name
HAVING COUNT(c_total.o_orderkey) > 10
ORDER BY avg_total_sales DESC;
