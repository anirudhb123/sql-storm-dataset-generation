
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 50000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
    WHERE s.s_acctbal > 50000
), 

OrderStats AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),

CustomerRevenue AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)

SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    p.p_retailprice,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(l.l_discount) AS avg_discount,
    SUM(cs.total_spent) AS total_customer_spent,
    ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY COUNT(DISTINCT o.o_orderkey) DESC) AS type_rank
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN CustomerRevenue cs ON cs.c_custkey = o.o_custkey
WHERE p.p_size BETWEEN 5 AND 20 
    AND (s.s_acctbal IS NULL OR s.s_acctbal < 100000 OR s.s_name IS NOT NULL)
GROUP BY p.p_partkey, p.p_name, s.s_name, p.p_retailprice, p.p_type
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_customer_spent DESC, supplier_name ASC;
