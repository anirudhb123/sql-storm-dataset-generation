WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000.00
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.level * 500.00
), 

RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-12-31'
), 

ItemSummary AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_quantity) AS total_quantity, 
           AVG(l.l_extendedprice) AS avg_price
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
), 

SuppliersWithComments AS (
    SELECT s.s_suppkey, s.s_name, COUNT(ps.ps_partkey) AS supply_count,
           STRING_AGG(ps.ps_comment, '; ') AS comments
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)

SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    sh.level AS supplier_level,
    is.p_name AS part_name,
    is.total_quantity,
    is.avg_price,
    SUM(oo.o_totalprice) AS total_order_value,
    COUNT(DISTINCT oo.o_orderkey) AS order_count
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierHierarchy sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN ItemSummary is ON is.total_quantity > 100
LEFT JOIN RankedOrders oo ON oo.o_orderkey IN (
    SELECT oo2.o_orderkey 
    FROM RankedOrders oo2 
    WHERE oo2.price_rank <= 10
)
LEFT JOIN SuppliersWithComments sc ON sc.s_supplycount >= 1
WHERE r.r_name LIKE 'N%' 
AND is.avg_price IS NOT NULL
GROUP BY r.r_name, n.n_name, sh.level, is.p_name, is.total_quantity, is.avg_price
HAVING SUM(oo.o_totalprice) > 10000
ORDER BY region, nation, supplier_level, total_order_value DESC;
