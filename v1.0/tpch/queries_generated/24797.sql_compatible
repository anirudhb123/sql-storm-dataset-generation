
WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_comment, 
           1 AS level, 
           NULL AS parent_suppkey
    FROM supplier
    WHERE s_name LIKE '%Acme%'
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_comment,
           sh.level + 1,
           sh.s_suppkey
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_suppkey <> sh.s_suppkey
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
part_suppliers AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, 
           ps.ps_supplycost, p.p_mfgr,
           RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice IS NOT NULL 
)
SELECT DISTINCT 
    r.r_name AS region, 
    n.n_name AS nation,
    s.s_name AS supplier, 
    p.p_name AS part,
    c.c_name AS customer,
    COALESCE(NULLIF(SUM(li.l_extendedprice * (1 - li.l_discount)), 0), 0) AS total_sales,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    CASE WHEN COUNT(DISTINCT o.o_orderkey) > 0 THEN 
          ROUND(SUM(li.l_extendedprice * (1 - li.l_discount)) / COUNT(DISTINCT o.o_orderkey), 2) 
          ELSE 0 END AS avg_order_value
FROM region r
JOIN nation n ON n.n_regionkey = r.r_regionkey
JOIN supplier s ON s.s_nationkey = n.n_nationkey
JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
JOIN part p ON p.p_partkey = ps.ps_partkey
LEFT JOIN lineitem li ON li.l_partkey = p.p_partkey
LEFT JOIN orders o ON o.o_orderkey = li.l_orderkey
LEFT JOIN customer c ON c.c_custkey = o.o_custkey
WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_mktsegment = c.c_mktsegment)
  AND p.p_comment NOT LIKE '%fragile%'
  AND EXISTS (SELECT 1 FROM supplier_hierarchy sh WHERE sh.s_suppkey = s.s_suppkey)
GROUP BY r.r_name, n.n_name, s.s_name, p.p_name, c.c_name
HAVING AVG(li.l_quantity) >
       (SELECT AVG(li2.l_quantity) FROM lineitem li2 WHERE li2.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31')
ORDER BY total_sales DESC, order_count ASC
LIMIT 10;
