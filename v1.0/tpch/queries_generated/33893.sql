WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, s_nationkey, 0 as level
    FROM supplier
    WHERE s_acctbal > (
        SELECT AVG(s_acctbal)
        FROM supplier
    )
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),

OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),

NationWithOrders AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT o.o_orderkey) as order_count
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_nationkey, n.n_name
)

SELECT 
    p.p_name, 
    p.p_brand, 
    p.p_type, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
    nwo.order_count,
    ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
LEFT JOIN NationWithOrders nwo ON sh.s_nationkey = nwo.n_nationkey
WHERE p.p_retailprice > (
    SELECT AVG(p2.p_retailprice) 
    FROM part p2 
    WHERE p2.p_type = p.p_type
)
AND (sh.level <= 2 OR sh.s_acctbal IS NULL)
GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_type, nwo.order_count
HAVING SUM(ps.ps_availqty) > 0
ORDER BY rank, total_available_quantity DESC;
