WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_nationkey = (SELECT n_nationkey FROM nation WHERE n_name = 'FRANCE')
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
)
, RankedLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey, l.l_quantity, l.l_extendedprice,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS rn
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '2023-01-01'
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
    AVG(COALESCE(s.s_acctbal, 0)) AS avg_supplier_balance
FROM
    orders o
LEFT JOIN 
    RankedLineItems li ON o.o_orderkey = li.l_orderkey 
LEFT JOIN 
    supplier s ON li.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    n.n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'EUROPE')
    AND EXISTS (SELECT 1 FROM SupplierHierarchy sh WHERE sh.s_suppkey = s.s_suppkey)
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY 
    total_revenue DESC
LIMIT 5;
