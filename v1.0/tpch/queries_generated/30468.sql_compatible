
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           0 AS level, 
           CAST(s.s_name AS VARCHAR) AS path
    FROM supplier s
    WHERE s.s_acctbal > 50000  
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           sh.level + 1,
           CAST(sh.path || ' -> ' || s.s_name AS VARCHAR)
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey + 1  
    WHERE s.s_acctbal > sh.s_acctbal  
), OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
), HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, os.total_sales,
           DENSE_RANK() OVER (ORDER BY os.total_sales DESC) AS sales_rank
    FROM orders o
    JOIN OrderSummary os ON o.o_orderkey = os.o_orderkey
    WHERE o.o_totalprice > 100000  
), SupplierParts AS (
    SELECT s.s_suppkey, p.p_partkey, SUM(ps.ps_availqty) AS total_available
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size >= 30
    GROUP BY s.s_suppkey, p.p_partkey
)

SELECT
    sh.level,
    sh.path,
    COALESCE(sp.total_available, 0) AS total_available_parts,
    hvo.o_orderkey,
    hvo.o_totalprice,
    hvo.total_sales
FROM SupplierHierarchy sh
LEFT JOIN SupplierParts sp ON sh.s_suppkey = sp.s_suppkey
LEFT JOIN HighValueOrders hvo ON hvo.o_orderkey = sp.p_partkey
WHERE hvo.sales_rank <= 10  
ORDER BY sh.level, total_available_parts DESC;
