WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS hierarchy_level
    FROM nation
    WHERE n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name LIKE 'Europe%')
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.hierarchy_level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
)
SELECT 
    s.s_name AS supplier_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank,
    COALESCE(c.c_acctbal, 0) AS account_balance,
    CONCAT(s.s_name, ' from ', n.n_name) AS supplier_info,
    CASE 
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000 THEN 'High Performer' 
        ELSE 'Low Performer' 
    END AS performance_category
FROM supplier s
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN customer c ON c.c_custkey = (SELECT o.o_custkey 
                                        FROM orders o 
                                        WHERE o.o_orderkey = l.l_orderkey 
                                        AND o.o_orderstatus = 'O' 
                                        LIMIT 1)
JOIN nation n ON s.s_nationkey = n.n_nationkey
WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY s.s_suppkey, s.s_name, n.n_name, c.c_acctbal
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) IS NOT NULL 
   OR COUNT(l.l_orderkey) > 10
ORDER BY total_sales DESC, sales_rank
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
