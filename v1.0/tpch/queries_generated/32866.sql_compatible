
WITH RECURSIVE SupplierCTE AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           (SELECT COUNT(*) 
            FROM partsupp ps 
            WHERE ps.ps_suppkey = s.s_suppkey) AS part_count
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           (SELECT COUNT(*) 
            FROM partsupp ps 
            WHERE ps.ps_suppkey = s.s_suppkey) AS part_count
    FROM supplier s
    JOIN SupplierCTE sc ON s.s_suppkey = sc.s_suppkey
    WHERE s.s_acctbal > 1000
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_price,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o 
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
    GROUP BY o.o_orderkey, o.o_custkey, o.o_totalprice
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
),
SupplierNames AS (
    SELECT DISTINCT s.s_name 
    FROM supplier s 
    JOIN partsupp p ON s.s_suppkey = p.ps_suppkey 
    WHERE p.ps_availqty IS NOT NULL AND p.ps_supplycost > 20.00
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_brand, 
    COALESCE(r.r_name, 'Unknown') AS region_name,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    CASE 
        WHEN p.p_size > 30 THEN 'Large' 
        ELSE 'Small' 
    END AS part_size_category
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON o.o_orderkey = l.l_orderkey
LEFT JOIN customer c ON c.c_custkey = o.o_custkey
LEFT JOIN supplier s ON s.s_suppkey = l.l_suppkey
LEFT JOIN nation n ON n.n_nationkey = s.s_nationkey
LEFT JOIN region r ON r.r_regionkey = n.n_regionkey
WHERE p.p_retailprice BETWEEN 100 AND 500
  AND l.l_shipdate >= DATE '1997-01-01'
  AND l.l_returnflag = 'N'
GROUP BY p.p_partkey, p.p_name, p.p_brand, r.r_name, p.p_size
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY total_revenue DESC
LIMIT 10
