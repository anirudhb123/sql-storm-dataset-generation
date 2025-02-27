
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, sh.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_nationkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    AND o.o_orderdate >= DATE '1997-01-01'
),
MonthlySales AS (
    SELECT 
        DATE_TRUNC('month', o.o_orderdate) AS month,
        SUM(o.o_totalprice) AS total_sales
    FROM CustomerOrders o
    GROUP BY DATE_TRUNC('month', o.o_orderdate)
)
SELECT 
    p.p_name,
    s.s_name,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MAX(s.s_acctbal) AS max_acct_balance,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank,
    CASE 
        WHEN MAX(s.s_acctbal) IS NULL THEN 'No Account'
        WHEN MAX(s.s_acctbal) > 1000 THEN 'High Value Supplier'
        ELSE 'Low Value Supplier' 
    END AS supplier_value
FROM lineitem l
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN CustomerOrders o ON l.l_orderkey = o.o_orderkey
WHERE l.l_returnflag = 'N'
AND (l.l_discount BETWEEN 0.05 AND 0.1 OR l.l_tax > 0.02)
GROUP BY p.p_partkey, s.s_suppkey, r.r_name, p.p_name
HAVING SUM(l.l_quantity) > (SELECT AVG(l2.l_quantity) FROM lineitem l2 WHERE l2.l_partkey = p.p_partkey)
ORDER BY total_revenue DESC;
