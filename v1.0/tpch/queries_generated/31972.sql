WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_suppkey = (SELECT MIN(supp.s_suppkey) FROM supplier supp)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_address, s.nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN supplier_hierarchy sh ON s.s_nationkey = sh.nationkey
    WHERE sh.level < 3
),
part_supplier_summary AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
customer_order_summary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    s.s_name AS supplier_name,
    s.s_address AS supplier_address,
    COALESCE(p.p_name, 'No Parts') AS part_name,
    COALESCE(ps.total_cost, 0) AS total_cost,
    c.c_name AS customer_name,
    c.order_count,
    c.total_spent,
    ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY c.total_spent DESC) AS customer_rank
FROM supplier_hierarchy s
LEFT JOIN part_supplier_summary ps ON s.s_suppkey = ps.p_partkey
LEFT JOIN customer_order_summary c ON c.c_custkey = (SELECT MIN(o.o_custkey) FROM orders o WHERE o.o_orderstatus = 'O')
WHERE ps.total_cost IS NOT NULL OR c.total_spent IS NOT NULL
ORDER BY supplier_name, part_name, total_cost DESC;
