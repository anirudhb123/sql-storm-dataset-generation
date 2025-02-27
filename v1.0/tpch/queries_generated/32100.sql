WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_custkey, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_custkey, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_orderkey > oh.o_orderkey
),
SupplierCosts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_supplycost * l.l_quantity) AS total_cost
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
RegionStats AS (
    SELECT r.r_name, COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_revenue
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= '2022-01-01'
    GROUP BY r.r_name
)
SELECT rh.o_orderkey, rh.o_orderdate, rh.o_totalprice, 
       RANK() OVER (PARTITION BY rh.o_custkey ORDER BY rh.o_totalprice DESC) AS rank,
       rs.r_name, rs.order_count, rs.total_revenue,
       COALESCE(sc.total_cost, 0) AS supplier_cost
FROM OrderHierarchy rh
LEFT JOIN RegionStats rs ON rs.order_count > 0
LEFT JOIN SupplierCosts sc ON sc.ps_partkey = (SELECT MAX(ps.ps_partkey)
                                                FROM partsupp ps 
                                                WHERE ps.ps_supplycost = (SELECT MIN(pss.ps_supplycost)
                                                                           FROM partsupp pss
                                                                           WHERE pss.ps_partkey = sc.ps_partkey))
WHERE rh.o_orderdate BETWEEN '2023-01-01' AND CURRENT_DATE
ORDER BY rh.o_orderdate, rank DESC;
