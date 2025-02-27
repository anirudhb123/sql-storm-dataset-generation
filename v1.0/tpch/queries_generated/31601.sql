WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_nationkey, c_acctbal, 0 AS level
    FROM customer
    WHERE c_nationkey = (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
)
SELECT 
    n.n_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS discounted_revenue,
    AVG(l.l_extendedprice * l.l_quantity) OVER (PARTITION BY n.n_name ORDER BY o.o_orderdate ROWS BETWEEN 1 PRECEDING AND CURRENT ROW) AS avg_extended_price,
    STRING_AGG(DISTINCT p.p_name, ', ') FILTER (WHERE p.p_retailprice > 100) AS expensive_parts,
    SUM(COALESCE(s.s_acctbal, 0)) AS total_supplier_balance
FROM orders o
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN part p ON l.l_partkey = p.p_partkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN CustomerHierarchy ch ON o.o_custkey = ch.c_custkey
WHERE 
    l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    AND (n.n_name IS NOT NULL OR ch.c_custkey IS NOT NULL)
GROUP BY n.n_name
HAVING COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY total_orders DESC;
