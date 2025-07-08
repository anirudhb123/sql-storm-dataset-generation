
WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
ranked_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1996-01-01' 
      AND o.o_orderdate < DATE '1997-01-01'
),
filtered_lineitems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
    GROUP BY l.l_orderkey
)
SELECT 
    p.p_name,
    SUM(COALESCE(ps.ps_availqty, 0)) AS total_available,
    AVG(COALESCE(co.total_sales, 0)) AS avg_total_sales,
    r.r_name AS supplier_region,
    sh.s_name AS supplier_name
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN ranked_orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.price_rank <= 10
    GROUP BY o.o_orderkey
) AS co ON ps.ps_suppkey = co.o_orderkey
JOIN supplier_hierarchy sh ON ps.ps_suppkey = sh.s_suppkey
JOIN nation n ON sh.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_type LIKE '%Steel%')
GROUP BY p.p_name, r.r_name, sh.s_name
HAVING SUM(COALESCE(ps.ps_availqty, 0)) > 100
   AND COUNT(DISTINCT sh.s_suppkey) > 2
ORDER BY avg_total_sales DESC;
