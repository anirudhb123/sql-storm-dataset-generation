WITH RECURSIVE supplier_rank AS (
    SELECT s_suppkey, s_name, s_acctbal,
           RANK() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rnk
    FROM supplier
),
high_value_parts AS (
    SELECT p_partkey, p_name, p_brand, p_retailprice, 
           CASE 
               WHEN p_retailprice IS NULL THEN 0
               ELSE p_retailprice * 0.1 
           END AS adjusted_price
    FROM part
),
order_details AS (
    SELECT o_orderkey, o_custkey, o_totalprice, 
           SUM(l_extendedprice * (1 - l_discount)) AS total_lineitem_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o_orderkey, o_custkey, o_totalprice
),
nation_part_supplier AS (
    SELECT n.n_name, COUNT(DISTINCT ps.suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN (SELECT ps.suppkey, ps.partkey FROM partsupp ps) ps ON n.n_nationkey = ps.nationkey
    GROUP BY n.n_name
),
part_supplier_info AS (
    SELECT p.p_partkey, p.p_name, s.s_name, ps.ps_supplycost,
           COALESCE(ps.ps_availqty, 0) AS available_quantity
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE p.p_retailprice > (SELECT AVG(p_retailprice) FROM part) OR s.s_acctbal < 100
)
SELECT n.n_name, p.p_name, s.s_name, total_order_value, 
       HOUR(o.o_orderdate) + MINUTE(o.o_orderdate)/60.0 AS order_time_hour,
       SUM(d.total_lineitem_price) AS calculated_total
FROM order_details d
JOIN orders o ON d.o_orderkey = o.o_orderkey
JOIN part_supplier_info p ON p.p_partkey IN (SELECT hp.p_partkey FROM high_value_parts hp)
JOIN nation_part_supplier np ON np.nation_key = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'ASIA')
LEFT JOIN supplier_rank sr ON sr.s_suppkey = p.s_suppkey AND sr.rnk <= 5
WHERE (o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL)
  AND (p.adjusted_price IS NOT NULL OR p.adjusted_price <> 0)
GROUP BY n.n_name, p.p_name, s.s_name, o.o_orderkey
HAVING SUM(d.total_lineitem_price) > (SELECT AVG(d.total_lineitem_price) FROM order_details)
ORDER BY calculated_total DESC, n.n_name, p.p_name
LIMIT 100 OFFSET 10;
