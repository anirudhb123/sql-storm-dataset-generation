WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, 1 AS level
    FROM orders o
    WHERE o.o_orderdate >= '1997-01-01'
    
    UNION ALL
    
    SELECT oh.o_orderkey, oh.o_totalprice, oh.o_orderdate, h.level + 1
    FROM orders oh
    JOIN OrderHierarchy h ON oh.o_orderkey < h.o_orderkey
    WHERE oh.o_orderdate >= '1997-01-01'
), 
SupplierSummary AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
CustomerOrderCount AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, 
           RANK() OVER (ORDER BY COUNT(o.o_orderkey) DESC) AS rnk
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    p.p_type,
    p.p_size,
    ROUND(AVG(p.p_retailprice), 2) AS avg_price,
    COALESCE(SUM(l.l_quantity), 0) AS total_quantity,
    MIN(l.l_shipdate) AS first_ship_date,
    MAX(l.l_shipdate) AS last_ship_date,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied,
    ss.total_cost AS supplier_cost
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN customer c ON o.o_custkey = c.c_custkey
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN SupplierSummary ss ON s.s_suppkey = ss.s_suppkey
WHERE p.p_size > 20 
AND p.p_retailprice < (SELECT AVG(p2.p_retailprice) FROM part p2)
AND (l.l_discount BETWEEN 0.05 AND 0.15 OR l.l_tax IS NULL)
GROUP BY p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, ss.total_cost
HAVING SUM(l.l_quantity) > 1000
ORDER BY avg_price DESC, unique_customers DESC;