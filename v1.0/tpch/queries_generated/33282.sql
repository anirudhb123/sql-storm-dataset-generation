WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS level
    FROM orders
    WHERE o_orderdate >= '2023-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    INNER JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
),

CustomerDetails AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_mktsegment,
           COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice ELSE 0 END), 0) AS total_returns,
           COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey
),

SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           COUNT(ps.ps_partkey) AS total_parts,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),

RankedOrders AS (
    SELECT oh.o_orderkey, oh.o_custkey, oh.o_totalprice, oh.level,
           RANK() OVER (PARTITION BY oh.o_custkey ORDER BY oh.o_totalprice DESC) AS order_rank
    FROM OrderHierarchy oh
)

SELECT DISTINCT cd.c_name, cd.total_orders, cd.total_returns, 
       ss.s_name, ss.total_parts, ss.total_supply_cost,
       ro.order_rank
FROM CustomerDetails cd
FULL OUTER JOIN SupplierStats ss ON cd.c_mktsegment = 'WH'
LEFT JOIN RankedOrders ro ON cd.c_custkey = ro.o_custkey
WHERE (cd.c_acctbal IS NOT NULL AND cd.c_acctbal > 1000)
  OR (ss.total_supply_cost IS NULL AND ss.total_parts < 10)
ORDER BY cd.c_name, ss.s_name DESC;
