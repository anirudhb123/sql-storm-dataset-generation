WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 10
),
OrderSummary AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
CustomerTotals AS (
    SELECT c.c_custkey, 
           SUM(o.o_totalprice) AS total_spent,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING SUM(o.o_totalprice) IS NOT NULL
),
SupplierPartData AS (
    SELECT s.s_name, 
           p.p_name, 
           SUM(ps.ps_availqty) AS total_available
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > 100
    GROUP BY s.s_name, p.p_name
)
SELECT 
    d.r_name AS region_name,
    SUM(COALESCE(ct.total_spent, 0)) AS total_customer_spending,
    STRING_AGG(DISTINCT sp.p_name, ', ') AS products_available,
    COUNT(DISTINCT oh.o_orderkey) AS orders_in_last_year
FROM region d
LEFT JOIN nation n ON d.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN CustomerTotals ct ON ct.c_custkey = c.c_custkey
LEFT JOIN SupplierPartData sp ON sp.total_available > 0
LEFT JOIN OrderSummary oh ON c.c_custkey = oh.o_orderkey
WHERE d.r_name LIKE '%East%' OR d.r_name IS NULL
GROUP BY d.r_name
ORDER BY total_customer_spending DESC;
