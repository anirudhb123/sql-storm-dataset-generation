WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.n_nationkey, 1 AS level
    FROM supplier s
    JOIN nation n ON s.n_nationkey = n.n_nationkey
    WHERE n.n_name = 'CANADA'
    
    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_address, s.n_nationkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice > 100.00
)

SELECT 
    sh.s_suppkey,
    sh.s_name,
    c.c_name AS customer_name,
    c.c_acctbal AS customer_balance,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    AVG(l.l_quantity) AS avg_quantity_per_order,
    COUNT(DISTINCT l.l_orderkey) AS order_count
FROM supplier_hierarchy sh
JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
JOIN lineitem l ON ps.ps_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
WHERE o.o_orderstatus = 'O' 
GROUP BY sh.s_suppkey, sh.s_name, customer_name, customer_balance
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_sales DESC
LIMIT 10;
