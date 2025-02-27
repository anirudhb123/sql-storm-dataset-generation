
WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s_suppkey, 
        s_name, 
        s_nationkey, 
        1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_suppkey <> sh.s_suppkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY l.l_extendedprice * (1 - l.l_discount)) AS median_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    GROUP BY o.o_orderkey
),
NationRevenue AS (
    SELECT 
        n.n_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY n.n_name
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
)
SELECT 
    p.p_name,
    ph.level AS supplier_level,
    os.o_orderkey,
    os.total_sales,
    nr.n_name,
    nr.revenue
FROM part p
LEFT JOIN SupplierHierarchy ph ON ph.s_suppkey = (SELECT MIN(s.s_suppkey) FROM supplier s WHERE s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA'))
JOIN OrderSummary os ON os.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE EXISTS (SELECT 1 FROM lineitem l WHERE l.l_orderkey = o.o_orderkey AND l.l_partkey = p.p_partkey))
JOIN NationRevenue nr ON nr.n_name IN ('USA', 'France')
WHERE p.p_retailprice BETWEEN 50.00 AND 200.00
ORDER BY nr.revenue DESC, os.total_sales DESC, ph.level;
