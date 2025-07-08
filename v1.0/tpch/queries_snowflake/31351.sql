WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = (sh.s_suppkey + 1)
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
TotalOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
),
SupplierPartCount AS (
    SELECT ps.ps_partkey, COUNT(ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT 
    n.n_name AS nation, 
    p.p_name AS part_name, 
    COALESCE(SUM(l.l_quantity), 0) AS total_quantity,
    AVG(s.s_acctbal) AS avg_supplier_balance,
    COUNT(DISTINCT o.o_orderkey) AS orders_count,
    RANK() OVER (ORDER BY COALESCE(SUM(l.l_quantity), 0) DESC) AS quantity_rank
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN supplier s ON s.s_suppkey = l.l_suppkey
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN nation n ON s.s_nationkey = n.n_nationkey 
LEFT JOIN SupplierPartCount spc ON spc.ps_partkey = p.p_partkey 
WHERE p.p_size > 10 AND s.s_acctbal IS NOT NULL
GROUP BY n.n_name, p.p_name
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_quantity DESC, avg_supplier_balance DESC;
