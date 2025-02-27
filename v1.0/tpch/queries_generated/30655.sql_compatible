
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 1 AS level
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_acctbal < ch.level * 1000
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
HighValueParts AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size > 10
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
FrequentOrders AS (
    SELECT o.o_custkey, COUNT(*) AS order_count
    FROM orders o
    WHERE o.o_orderdate >= DATE '1996-01-01'
    GROUP BY o.o_custkey
    HAVING COUNT(*) > 5
)
SELECT 
    c.c_name AS customer_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    l.l_quantity,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_sales,
    RANK() OVER (PARTITION BY n.n_name ORDER BY COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) DESC) AS sales_rank,
    CASE 
        WHEN MAX(COALESCE(f.order_count, 0)) > 0 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer'
    END AS buying_behavior
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN supplier s ON l.l_suppkey = s.s_suppkey
JOIN HighValueParts p ON l.l_partkey = p.p_partkey
LEFT JOIN FrequentOrders f ON c.c_custkey = f.o_custkey
WHERE l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
GROUP BY c.c_name, n.n_name, s.s_name, p.p_name, l.l_quantity
ORDER BY total_sales DESC, sales_rank;
