WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, 1 AS Level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, oh.o_custkey, oh.o_orderdate, (oh.o_totalprice * (1 + (CASE WHEN l.l_discount > 0 THEN l.l_discount ELSE 0 END))) AS AdjustedPrice,
           oh.Level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N' AND oh.Level < 5
),
SupplierParts AS (
    SELECT ps.ps_partkey, s.s_suppkey, SUM(ps.ps_availqty) AS TotalQty, 
           COUNT(DISTINCT s.s_nationkey) AS DistinctNations
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_suppkey
)
SELECT p.p_name, 
       p.p_retailprice, 
       COALESCE(SUM(l.l_quantity), 0) AS TotalSold, 
       COALESCE(AVG(l.l_discount), 0) AS AvgDiscount,
       (SELECT COUNT(DISTINCT c.c_custkey)
        FROM customer c
        WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA'))) AS AsianCustomers,
       ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY p.p_name) AS PartRank,
       (SELECT COUNT(*) FROM OrderHierarchy) AS CountOfActiveOrders
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN SupplierParts sp ON p.p_partkey = sp.ps_partkey
GROUP BY p.p_partkey, p.p_name, p.p_retailprice
HAVING AVG(p.p_retailprice) > (SELECT AVG(ps.ps_supplycost) FROM partsupp ps)
   AND COUNT(sp.s_suppkey) > 1
ORDER BY TotalSold DESC, AvgDiscount DESC 
OFFSET 3 ROWS FETCH NEXT 5 ROWS ONLY;
