WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           CAST(s.s_name AS varchar(100)) AS hierarchy_name
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           CONCAT(sh.hierarchy_name, ' > ', s.s_name)
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal > sh.s_acctbal
),
part_supplier_stats AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) as total_avail_qty,
           COUNT(*) as total_suppliers,
           MAX(s.s_acctbal) as max_acctbal
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
order_details AS (
    SELECT o.o_orderkey, AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price,
           DENSE_RANK() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_discount IS NOT NULL
    GROUP BY o.o_orderkey
)
SELECT p.p_partkey, p.p_name, p.p_brand, ps.total_suppliers, ps.total_avail_qty,
       od.avg_price, od.order_rank,
       CASE 
           WHEN ps.max_acctbal IS NULL THEN 'No Account Balance'
           WHEN ps.max_acctbal < 1000 THEN 'Low Balance'
           ELSE 'Adequate Balance'
       END AS balance_status
FROM part p
LEFT JOIN part_supplier_stats ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN order_details od ON od.o_orderkey = (
    SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (
          SELECT c.c_custkey FROM customer c WHERE c.c_name LIKE '%Corp%'
          )
    ORDER BY o.o_orderdate DESC LIMIT 1
)
WHERE ps.total_avail_qty IS NOT NULL AND ps.total_suppliers > 0
AND (p.p_retailprice BETWEEN 50 AND 150 OR p.p_size IS NULL)
ORDER BY od.avg_price DESC, p.p_brand ASC
FETCH FIRST 10 ROWS ONLY
UNION ALL
SELECT NULL AS p_partkey, 'Total' AS p_name, NULL AS p_brand, 
       COUNT(*) AS total_suppliers, SUM(ps.total_avail_qty) AS total_avail_qty,
       AVG(od.avg_price) AS avg_price, NULL AS order_rank,
       NULL AS balance_status
FROM part_supplier_stats ps
JOIN order_details od ON od.o_orderkey IS NOT NULL
WHERE od.avg_price IS NOT NULL;
