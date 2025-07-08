
WITH RECURSIVE RegionHierarchy AS (
    SELECT r_regionkey, r_name, r_comment, 0 AS level
    FROM region
    WHERE r_regionkey = 1
    
    UNION ALL
    
    SELECT r.r_regionkey, r.r_name, r.r_comment, rh.level + 1
    FROM region r
    INNER JOIN RegionHierarchy rh ON r.r_regionkey = rh.r_regionkey + 1
),
BestSupplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_availqty
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
    HAVING SUM(ps.ps_availqty) > (
        SELECT AVG(ps_sub.ps_availqty)
        FROM partsupp ps_sub
        WHERE ps_sub.ps_partkey = ps.ps_partkey
    )
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
MaxOrderValue AS (
    SELECT o.o_orderkey, o.o_totalprice
    FROM orders o
    WHERE o.o_totalprice = (SELECT MAX(o_sub.o_totalprice) FROM orders o_sub)
),
RankedLineItems AS (
    SELECT l.*, ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_quantity DESC) AS rn
    FROM lineitem l
    WHERE l.l_shipdate >= '1997-01-01'
)
SELECT p.p_partkey, p.p_name, s.s_name, co.order_count, rh.level AS region_level,
       COALESCE(SUM(li.l_extendedprice * (1 - li.l_discount)), 0) AS total_revenue,
       CASE 
           WHEN COUNT(DISTINCT bs.ps_suppkey) > 1 THEN 'Multiple Suppliers' 
           ELSE 'Single Supplier' 
       END AS supplier_status,
       COUNT(li.l_orderkey) FILTER (WHERE li.l_returnflag = 'R') AS returned_items
FROM part p
LEFT JOIN BestSupplier bs ON p.p_partkey = bs.ps_partkey
LEFT JOIN supplier s ON bs.ps_suppkey = s.s_suppkey
LEFT JOIN CustomerOrders co ON co.c_custkey = s.s_nationkey 
LEFT JOIN RankedLineItems li ON li.l_partkey = p.p_partkey
LEFT JOIN RegionHierarchy rh ON rh.r_regionkey = s.s_nationkey
WHERE p.p_retailprice BETWEEN 10 AND 100
  AND rh.level IS NOT NULL
GROUP BY p.p_partkey, p.p_name, s.s_name, co.order_count, rh.level
ORDER BY total_revenue DESC
LIMIT 100;
