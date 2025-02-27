WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
part_supplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 100 AND ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
),
total_orders AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_custkey
),
qualified_customers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, to.total_value
    FROM customer c
    JOIN total_orders to ON c.c_custkey = to.o_custkey
    WHERE c.c_acctbal > 5000
)
SELECT 
    sh.s_name AS supplier_name,
    p.p_name AS part_name,
    COALESCE(qc.c_name, 'No qualified customer') AS customer_name,
    p.ps_availqty,
    p.ps_supplycost,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY p.ps_supplycost DESC) AS supply_rank,
    CASE 
        WHEN qc.total_value IS NULL THEN 'No Orders'
        ELSE CONCAT('Total Sales: ', CAST(qc.total_value AS varchar(20)))
    END AS sales_info
FROM supplier_hierarchy sh
LEFT JOIN part_supplier p ON sh.s_suppkey = p.ps_suppkey
LEFT JOIN qualified_customers qc ON qc.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = sh.s_nationkey LIMIT 1)
WHERE sh.level <= 3
ORDER BY p.p_partkey, supply_rank;
