WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
  
    UNION ALL
  
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        sh.level + 1 
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spend,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_nationkey
)
SELECT 
    ph.p_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount,
    COUNT(DISTINCT so.s_suppkey) AS num_suppliers,
    COALESCE(r.r_name, 'Unknown') AS region_name
FROM part ph
JOIN lineitem l ON ph.p_partkey = l.l_partkey
LEFT JOIN partsupp ps ON ph.p_partkey = ps.ps_partkey
LEFT JOIN supplier so ON ps.ps_suppkey = so.s_suppkey
LEFT JOIN nation n ON so.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN CustomerOrders co ON co.total_orders > 0
WHERE l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
AND (l.l_discount > 0.1 OR l.l_tax IS NULL)
GROUP BY ph.p_name, r.r_name
HAVING SUM(l.l_quantity) > 100
ORDER BY total_quantity DESC, avg_price_after_discount DESC;