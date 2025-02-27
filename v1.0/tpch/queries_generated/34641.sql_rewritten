WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) 
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey 
    WHERE s.s_acctbal > sh.s_acctbal
),
MostCommonParts AS (
    SELECT ps.ps_partkey, COUNT(*) AS total_suppliers
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING COUNT(*) > (SELECT AVG(total_suppliers) FROM (SELECT COUNT(*) AS total_suppliers FROM partsupp GROUP BY ps_partkey) AS avg_parts)
),
SupplierOrders AS (
    SELECT o.o_orderkey, c.c_name, o.o_totalprice, ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate <= '1997-12-31'
)
SELECT 
    p.p_name,
    p.p_mfgr,
    sh.s_name AS supplier_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    MAX(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE NULL END) AS max_returned_quantity,
    COUNT(DISTINCT CASE WHEN l.l_shipmode = 'AIR' THEN o.o_orderkey END) AS air_shipments,
    AVG(o.o_totalprice) AS avg_order_price
FROM 
    part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN supplier sh ON ps.ps_suppkey = sh.s_suppkey
    LEFT JOIN SupplierOrders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_size BETWEEN 10 AND 20 
    AND p.p_retailprice IS NOT NULL 
    AND o.rn <= 5
GROUP BY 
    p.p_name, p.p_mfgr, sh.s_name
ORDER BY 
    total_revenue DESC 
LIMIT 10;