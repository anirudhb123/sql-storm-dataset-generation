WITH RECURSIVE Supplier_Hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN Supplier_Hierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 3
),
Expenses AS (
    SELECT c.c_custkey, c.c_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_expenses
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-12-31'
    GROUP BY c.c_custkey, c.c_name
),
Top_Customers AS (
    SELECT c.c_custkey, c.c_name, ce.total_expenses
    FROM customer c
    JOIN Expenses ce ON c.c_custkey = ce.c_custkey
    ORDER BY ce.total_expenses DESC
    LIMIT 10
)
SELECT 
    s.s_name AS supplier_name,
    COALESCE(SUM(l.l_extendedprice), 0) AS total_sales,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) = 0 THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status,
    ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(l.l_extendedprice) DESC) AS rank_within_nation
FROM supplier s
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN Top_Customers tc ON o.o_custkey = tc.c_custkey
WHERE tc.c_custkey IS NOT NULL 
  AND (l.l_returnflag IS NULL OR l.l_returnflag != 'R')
GROUP BY s.s_name, s.s_nationkey
ORDER BY total_sales DESC
LIMIT 50;
