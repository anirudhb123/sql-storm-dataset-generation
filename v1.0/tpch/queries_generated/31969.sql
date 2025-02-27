WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
), RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-12-31'
), SupplierParts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_availqty
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
), NationWithComment AS (
    SELECT n.n_nationkey, n.n_name, 
           CASE 
               WHEN n.n_comment IS NULL THEN 'No comment provided'
               ELSE n.n_comment 
           END AS comment
    FROM nation n
    WHERE n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA')
)
SELECT DISTINCT 
    p.p_name, 
    s.s_name, 
    CASE 
        WHEN SUM(l.l_extendedprice) > 10000 THEN 'High Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category,
    nh.n_name AS nation_name,
    oh.price_rank
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN SupplierParts sp ON sp.ps_partkey = p.p_partkey
JOIN supplier s ON s.s_suppkey = sp.ps_suppkey
JOIN RankedOrders oh ON oh.o_orderkey = l.l_orderkey
JOIN NationWithComment nh ON nh.n_nationkey = s.s_nationkey
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
WHERE l.l_shipdate BETWEEN '2023-06-01' AND '2023-06-30'
AND p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice < 50)
GROUP BY 
    p.p_name, 
    s.s_name, 
    nh.n_name,
    oh.price_rank
ORDER BY 
    revenue_category DESC, 
    p.p_name;
