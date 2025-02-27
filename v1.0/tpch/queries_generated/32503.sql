WITH RECURSIVE SupplierTree AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, st.level + 1
    FROM supplier s
    INNER JOIN SupplierTree st ON st.s_nationkey = s.s_nationkey
    WHERE st.level < 3
), RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F')
), HighValueLineItems AS (
    SELECT l.*, 
           (l.l_extendedprice * (1 - l.l_discount)) AS net_price,
           CASE 
               WHEN l.l_returnflag = 'R' THEN 'Returned'
               ELSE 'Non-returned'
           END AS return_status
    FROM lineitem l
    WHERE l.l_quantity > (
        SELECT AVG(l2.l_quantity) FROM lineitem l2 WHERE l2.l_orderkey = l.l_orderkey
    )
)
SELECT r.r_name, 
       COALESCE(SUM(li.net_price), 0) AS total_net_sales,
       COUNT(DISTINCT ho.o_orderkey) AS high_value_orders
FROM region r
LEFT OUTER JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT OUTER JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT OUTER JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT OUTER JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT OUTER JOIN HighValueLineItems li ON p.p_partkey = li.l_partkey
LEFT OUTER JOIN RankedOrders ho ON ho.o_orderkey = li.l_orderkey
WHERE r.r_name LIKE '%West%'
GROUP BY r.r_name
HAVING COUNT(DISTINCT n.n_nationkey) > 1
ORDER BY total_net_sales DESC;
