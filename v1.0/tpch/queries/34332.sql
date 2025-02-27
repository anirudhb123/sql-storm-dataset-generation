WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    INNER JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE oh.level < 5
),
RankedSupplier AS (
    SELECT s.s_suppkey, s.s_name, 
           DENSE_RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) as rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
FilteredCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 
           CASE 
               WHEN c.c_acctbal IS NULL THEN 'Balance Unknown'
               WHEN c.c_acctbal < 1000 THEN 'Low Balance'
               WHEN c.c_acctbal BETWEEN 1000 AND 5000 THEN 'Medium Balance'
               ELSE 'High Balance'
           END AS balance_category
    FROM customer c
    WHERE c.c_mktsegment = 'BUILDING'
)
SELECT 
    p.p_partkey,
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COALESCE(rn.r_name, 'Unknown Region') AS supplier_region,
    fc.balance_category,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN supplier s ON s.s_suppkey = l.l_suppkey
LEFT JOIN RankedSupplier rs ON s.s_suppkey = rs.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region rn ON n.n_regionkey = rn.r_regionkey
LEFT JOIN FilteredCustomers fc ON o.o_custkey = fc.c_custkey
WHERE l.l_shipdate >= cast('1998-10-01' as date) - INTERVAL '6 months'
AND p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100)
GROUP BY p.p_partkey, p.p_name, rn.r_name, fc.balance_category
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
ORDER BY total_revenue DESC, p.p_name
LIMIT 100;