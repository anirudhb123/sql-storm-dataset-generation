WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal > 5000
), 

LineItemStats AS (
    SELECT 
        li.l_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
        AVG(li.l_quantity) AS avg_quantity,
        COUNT(*) AS item_count
    FROM lineitem li
    WHERE li.l_shipdate >= '1997-01-01' AND li.l_shipdate < '1997-10-01'
    GROUP BY li.l_orderkey
)

SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT li.l_orderkey) AS total_orders,
    SUM(ls.total_sales) AS total_sales,
    AVG(ls.avg_quantity) AS avg_quantity,
    MAX(s.s_acctbal) AS max_supplier_balance,
    COUNT(DISTINCT s.s_suppkey) FILTER (WHERE s.s_acctbal > 10000) AS high_balance_suppliers
FROM nation n
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN lineitem li ON li.l_partkey = ps.ps_partkey
LEFT JOIN LineItemStats ls ON li.l_orderkey = ls.l_orderkey
WHERE n.n_name LIKE 'A%' AND r.r_comment IS NOT NULL
GROUP BY n.n_name, r.r_name
HAVING COUNT(DISTINCT li.l_orderkey) > 5
ORDER BY total_sales DESC;