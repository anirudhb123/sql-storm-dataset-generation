WITH RECURSIVE OrdersHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= '2023-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus, oh.level + 1
    FROM orders o
    INNER JOIN OrdersHierarchy oh ON o.o_orderkey = oh.o_orderkey AND oh.level < 5
),
PartSupplierDetails AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, s.s_nationkey, s.s_acctbal
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal > 5000
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(COALESCE(l.l_extendedprice, 0)) AS total_sales,
    AVG(l.l_discount) AS average_discount,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY p.p_retailprice) AS median_retail_price,
    STRING_AGG(DISTINCT p.p_name, ', ') AS product_names,
    ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(l.l_extendedprice) DESC) AS ranking
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN PartSupplierDetails psd ON l.l_partkey = psd.p_partkey
WHERE (l.l_shipdate >= '2023-01-01' OR l.l_shipdate IS NULL)
AND l.l_returnflag = 'N'
GROUP BY r.r_name, n.n_name
HAVING SUM(COALESCE(l.l_extendedprice, 0)) > 10000
ORDER BY total_sales DESC, region;
