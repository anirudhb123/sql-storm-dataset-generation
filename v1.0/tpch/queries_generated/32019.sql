WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
FrequentCustomers AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 5
),
DetailedLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, (l.l_extendedprice * (1 - l.l_discount)) AS effective_price,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS row_num
    FROM lineitem l
)
SELECT p.p_name, p.p_brand, p.p_type, 
       SUM(dli.effective_price) AS total_revenue,
       COUNT(DISTINCT fc.c_custkey) AS customer_count,
       MAX(sh.level) AS supplier_level,
       r.r_name AS region_name
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
JOIN DetailedLineItems dli ON dli.l_partkey = p.p_partkey
JOIN orders o ON dli.l_orderkey = o.o_orderkey
JOIN FrequentCustomers fc ON o.o_custkey = fc.c_custkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE p.p_retailprice IS NOT NULL
  AND (p.p_size >= 10 OR p.p_mfgr = 'Manufacturer#1')
  AND (o.o_orderstatus = 'F' OR o.o_orderstatus IS NULL)
GROUP BY p.p_name, p.p_brand, p.p_type, r.r_name
HAVING total_revenue > 10000
ORDER BY total_revenue DESC;
