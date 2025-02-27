WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal, 
        CAST(c.c_name AS VARCHAR(255)) AS hierarchy_path,
        1 AS level
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
    
    UNION ALL
    
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal, 
        CAST(ch.hierarchy_path || ' -> ' || c.c_name AS VARCHAR(255)),
        ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_custkey
    WHERE c.c_acctbal < (SELECT AVG(c_acctbal) FROM customer)
)

SELECT 
    p.p_partkey, 
    p.p_name, 
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_sales,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank,
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    CASE 
        WHEN SUM(l.l_quantity) IS NULL THEN 'No Sales'
        ELSE 'Sales Exist'
    END AS sales_status
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE p.p_retailprice > 100
GROUP BY p.p_partkey, p.p_name, r.r_name, n.n_name, s.s_name
HAVING COUNT(l.l_orderkey) > 5
ORDER BY region_name, total_sales DESC
LIMIT 10;
