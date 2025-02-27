WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_nationkey = 1
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, h.level + 1
    FROM nation n
    JOIN NationHierarchy h ON n.n_regionkey = h.n_regionkey
)
SELECT 
    r.r_name AS region_name, 
    SUM(ol.total_price) AS total_sales,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(s.s_acctbal) AS avg_supplier_balance,
    MAX(ol.line_count) AS max_line_count,
    STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers,
    CASE 
        WHEN AVG(ol.total_price) IS NULL THEN 'No Sales'
        WHEN AVG(ol.total_price) > 1000 THEN 'High Revenue'
        ELSE 'Regular Revenue' 
    END AS revenue_status
FROM (SELECT 
          l.l_orderkey, 
          SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
          COUNT(l.l_linenumber) AS line_count
      FROM lineitem l
      GROUP BY l.l_orderkey) ol
JOIN orders o ON ol.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN partsupp ps ON EXISTS (
      SELECT 1 
      FROM part p 
      WHERE p.p_partkey = ps.ps_partkey 
      AND p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 500)
) 
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN NationHierarchy nh ON n.n_nationkey = nh.n_nationkey
GROUP BY r.r_name
HAVING SUM(ol.total_price) > (SELECT AVG(total_price) FROM (
    SELECT SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM lineitem l
    GROUP BY l.l_orderkey
) subquery)
ORDER BY total_sales DESC;
