WITH RECURSIVE supplier_chain AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level 
    FROM supplier s 
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 10000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sc.level + 1 
    FROM supplier_chain sc
    JOIN partsupp ps ON ps.ps_suppkey = sc.s_suppkey 
    JOIN part p ON ps.ps_partkey = p.p_partkey 
    WHERE p.p_size BETWEEN 10 AND 20
)
, order_summary AS (
    SELECT o.o_orderkey, COUNT(li.l_orderkey) AS total_lineitems, SUM(o.o_totalprice) AS total_price
    FROM orders o
    LEFT JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY o.o_orderkey
)
, customer_orders AS (
    SELECT c.c_custkey, c.c_name, os.o_orderkey
    FROM customer c
    JOIN order_summary os ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = os.o_orderkey)
    WHERE c.c_acctbal > (SELECT AVG(c1.c_acctbal) FROM customer c1) 
)
SELECT DISTINCT 
    sc.s_name AS supplier_name, 
    co.c_name AS customer_name, 
    os.total_price, 
    (CASE 
        WHEN os.total_price IS NULL THEN 'No Orders' 
        ELSE 'Total Orders ' || COUNT(os.o_orderkey)
    END) AS order_status,
    SUM(COALESCE(li.l_discount, 0)) OVER (PARTITION BY sc.s_suppkey) AS total_discount,
    REPLACE(TRIM(sc.s_name), ' ', '_') AS formatted_supplier_name
FROM supplier_chain sc
LEFT JOIN partsupp ps ON ps.ps_suppkey = sc.s_suppkey
LEFT JOIN order_summary os ON os.o_orderkey = ps.ps_partkey
LEFT JOIN customer_orders co ON co.o_orderkey = os.o_orderkey
WHERE sc.level = (SELECT MAX(level) FROM supplier_chain)
  AND (sc.s_acctbal IS NOT NULL AND sc.s_acctbal > 50000 OR sc.s_name LIKE 'Supplier%')
ORDER BY total_price DESC, supplier_name ASC
LIMIT 10 OFFSET (SELECT COUNT(DISTINCT c.c_custkey) FROM customer c) % 5;
