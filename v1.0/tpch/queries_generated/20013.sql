WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, CAST(s_name AS varchar(255)) AS path
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           CONCAT(sh.path, ' -> ', s.s_name) AS path
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_suppkey <> sh.s_suppkey
),
part_count AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_availqty
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'R' AND l.l_shipmode IN ('AIR', 'GROUND')
    GROUP BY o.o_orderkey
),
detailed_info AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, pc.total_availqty, os.total_price,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY os.total_price DESC) as rank
    FROM part p
    LEFT JOIN part_count pc ON p.p_partkey = pc.ps_partkey
    LEFT JOIN order_summary os ON p.p_partkey = os.o_orderkey
    WHERE p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100.00)
)
SELECT dh.*, s.name AS supplier_name, 
       CASE WHEN dh.total_price IS NULL THEN 'No Sales' ELSE 'Sales Present' END AS sales_status
FROM detailed_info dh
LEFT JOIN supplier_hierarchy s ON dh.p_brand = s.s_name
WHERE dh.rank <= 5 AND (dh.total_availqty IS NOT NULL OR dh.total_price IS NULL)
ORDER BY dh.p_partkey, sales_status;
