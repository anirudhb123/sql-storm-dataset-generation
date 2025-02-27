WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS level
    FROM orders
    WHERE o_orderstatus = 'O' AND o_orderdate > '2022-01-01'
    UNION ALL
    SELECT o.orderkey, o.custkey, o.orderdate, o.totalprice, oh.level + 1
    FROM orders o
    INNER JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
      AND o.o_orderstatus = 'O'
), SupplierWithNS AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, COUNT(DISTINCT ps.ps_partkey) AS supplier_parts_count
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
    HAVING COUNT(DISTINCT ps.ps_partkey) > 5
), LineItemStats AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_quantity DESC) AS revenue_rank,
           DENSE_RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_density
    FROM lineitem l
    GROUP BY l.l_orderkey
), DetailedOrderInfo AS (
    SELECT oh.o_orderkey, 
           oh.o_orderdate,
           oh.o_totalprice,
           ns.s_suppkey, 
           ns.s_name,
           li.total_revenue,
           li.revenue_rank,
           CASE WHEN li.total_revenue IS NULL THEN 'No Revenue' ELSE 'Has Revenue' END AS revenue_status
    FROM OrderHierarchy oh
    LEFT JOIN SupplierWithNS ns ON ns.s_suppkey = (SELECT ps.ps_suppkey 
                                                   FROM partsupp ps
                                                   INNER JOIN lineitem li ON ps.ps_partkey = li.l_partkey
                                                   WHERE li.l_orderkey = oh.o_orderkey
                                                   LIMIT 1)
    LEFT JOIN LineItemStats li ON li.l_orderkey = oh.o_orderkey
)
SELECT d.o_orderkey, 
       d.o_orderdate, 
       d.o_totalprice, 
       d.s_name, 
       d.total_revenue,
       COALESCE(NULLIF(d.revenue_status, 'Has Revenue'), 'Unknown') AS final_revenue_status
FROM DetailedOrderInfo d
WHERE d.o_totalprice > (SELECT AVG(o.o_totalprice) 
                         FROM orders o 
                         WHERE o.o_orderdate <= CURDATE() - INTERVAL '1' YEAR)
ORDER BY d.o_totalprice DESC
LIMIT 100 OFFSET 25;
