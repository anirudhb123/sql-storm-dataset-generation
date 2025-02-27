
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
),
PartSupplierCount AS (
    SELECT ps_partkey, COUNT(*) AS supplier_count
    FROM partsupp
    GROUP BY ps_partkey
),
AvgLineitemPrice AS (
    SELECT l_partkey, AVG(l_extendedprice * (1 - l_discount)) AS avg_price
    FROM lineitem
    WHERE l_shipdate >= DATE '1996-01-01' 
    GROUP BY l_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COALESCE(ps.supplier_count, 0) AS supplier_count,
    COALESCE(a.avg_price, 0) AS avg_price,
    s.s_name AS supplier_name,
    o.order_rank,
    CASE 
        WHEN o.order_rank < 5 THEN 'Top Order'
        ELSE 'Standard Order'
    END AS order_category
FROM part p
LEFT JOIN PartSupplierCount ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN AvgLineitemPrice a ON p.p_partkey = a.l_partkey
LEFT JOIN RankedOrders o ON o.o_orderkey IN (
    SELECT l_orderkey 
    FROM lineitem 
    WHERE l_partkey = p.p_partkey
)
LEFT JOIN SupplierHierarchy s ON s.s_nationkey = (
    SELECT n.n_nationkey 
    FROM nation n 
    WHERE n.n_name = 'USA'
)
WHERE 
    p.p_size IN (1, 2, 3) 
    AND (COALESCE(ps.supplier_count, 0) > 5)
    AND (s.s_acctbal IS NOT NULL OR a.avg_price IS NOT NULL)
ORDER BY p.p_partkey, o.order_rank;
