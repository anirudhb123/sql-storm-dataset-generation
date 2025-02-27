WITH RECURSIVE CustomerOrderCTE AS (
    SELECT c.c_custkey,
           c.c_name,
           o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           o.o_orderstatus,
           1 AS order_level
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT c.c_custkey,
           c.c_name,
           o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           o.o_orderstatus,
           co.order_level + 1
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN CustomerOrderCTE co ON co.o_orderkey = o.o_orderkey
)
SELECT n.n_name,
       r.r_name,
       p.p_name,
       COUNT(DISTINCT c.c_custkey) AS total_customers,
       SUM(CASE 
               WHEN li.l_discount > 0.05 THEN li.l_extendedprice * (1 - li.l_discount)
               ELSE li.l_extendedprice
           END) AS total_revenue,
       AVG(li.l_quantity) AS avg_quantity,
       MAX(li.l_tax) AS max_tax_rate,
       MIN(li.l_shipdate) AS earliest_ship_date,
       STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_phone, ')'), '; ') AS suppliers_info
FROM lineitem li
JOIN partsupp ps ON li.l_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN orders o ON li.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE li.l_returnflag = 'N' 
  AND li.l_linestatus = 'O'
  AND li.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
  AND p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
GROUP BY n.n_name, r.r_name, p.p_name
HAVING COUNT(DISTINCT c.c_custkey) > 5
ORDER BY total_revenue DESC
LIMIT 10;