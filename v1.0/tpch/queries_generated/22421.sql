WITH RECURSIVE supplier_rank AS (
    SELECT s_suppkey,
           s_name,
           s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rank
    FROM supplier
),
overpriced_parts AS (
    SELECT p_partkey,
           p_name,
           p_retailprice,
           CASE
               WHEN p_retailprice > 100.00 THEN 'High'
               WHEN p_retailprice BETWEEN 50.00 AND 100.00 THEN 'Medium'
               ELSE 'Low'
           END AS price_category
    FROM part
),
order_info AS (
    SELECT o_orderkey,
           o_orderstatus,
           o_totalprice,
           o_orderdate,
           LAG(o_totalprice, 1, 0) OVER (ORDER BY o_orderdate) AS prev_totalprice
    FROM orders
    WHERE o_orderdate >= '2023-01-01'
      AND o_orderstatus IN ('O', 'F')
),
customer_orders AS (
    SELECT c.c_custkey,
           c.c_name,
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING total_spent > (SELECT AVG(total_spent) FROM (
                                SELECT SUM(o_totalprice) AS total_spent
                                FROM orders
                                GROUP BY o_custkey) AS avg_spending)
),
lineitem_summary AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_revenue,
           COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS return_count
    FROM lineitem l
    GROUP BY l.l_orderkey
),
supplier_part_info AS (
    SELECT s.s_suppkey,
           sp.ps_partkey,
           SUM(sp.ps_availqty) AS total_availqty,
           MAX(sp.ps_supplycost) AS max_supplycost
    FROM supplier s
    JOIN partsupp sp ON s.s_suppkey = sp.ps_suppkey
    GROUP BY s.s_suppkey, sp.ps_partkey
)
SELECT p.p_partkey,
       p.p_name,
       p.p_retailprice,
       COALESCE(NULLIF(r.r_name, ''), 'Unknown') AS region,
       c.c_name AS customer_name,
       COALESCE(s.r_nationkey, 0) AS supplier_nation,
       sr.rank AS supplier_rank,
       os.o_orderkey AS order_number,
       ls.total_line_revenue,
       CASE
           WHEN ls.return_count > 0 THEN 'Returned'
           ELSE 'Not Returned'
       END AS return_status
FROM part p
LEFT JOIN region r ON (r.r_regionkey) = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = (SELECT MIN(s_nationkey) FROM supplier))
LEFT JOIN customer_orders c ON c.order_count > 0
LEFT JOIN lineitem_summary ls ON ls.l_orderkey = (SELECT MAX(o.o_orderkey) FROM orders o WHERE o.o_orderkey < (SELECT MAX(o_orderkey) FROM orders))
LEFT JOIN supplier_rank sr ON sr.s_suppkey = (SELECT MIN(s.s_suppkey) FROM supplier s)
LEFT JOIN supplier_part_info sp ON sp.ps_partkey = p.p_partkey
LEFT JOIN orders os ON os.o_orderkey IN (SELECT DISTINCT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O' AND o.o_totalprice > p.p_retailprice * 2)
WHERE p.p_retailprice IS NOT NULL
ORDER BY p.p_partkey DESC
LIMIT 100
OFFSET 50;
