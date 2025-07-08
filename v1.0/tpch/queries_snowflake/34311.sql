
WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_custkey, 1 AS level
    FROM orders o
    WHERE o.o_orderdate >= '1997-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_custkey, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
),
PartAggregates AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
CustomerNations AS (
    SELECT c.c_custkey, n.n_nationkey, n.n_name
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE c.c_acctbal > 500
),
SupplierOrders AS (
    SELECT s.s_suppkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_returnflag = 'N'
    GROUP BY s.s_suppkey
)
SELECT
    oh.o_orderkey,
    oh.o_orderdate,
    oh.o_totalprice,
    cn.n_name AS customer_nation,
    ps.total_available,
    ps.avg_supply_cost,
    so.total_sales,
    ROW_NUMBER() OVER (PARTITION BY cn.n_name ORDER BY oh.o_totalprice DESC) AS rank
FROM OrderHierarchy oh
LEFT JOIN CustomerNations cn ON oh.o_custkey = cn.c_custkey
LEFT JOIN PartAggregates ps ON ps.ps_partkey = (
    SELECT l.l_partkey
    FROM lineitem l
    WHERE l.l_orderkey = oh.o_orderkey
    LIMIT 1
)
LEFT JOIN SupplierOrders so ON so.s_suppkey = (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_orderkey = oh.o_orderkey
    LIMIT 1
)
WHERE oh.level = 1
AND ps.total_available IS NOT NULL
AND so.total_sales > 1000
GROUP BY 
    oh.o_orderkey,
    oh.o_orderdate,
    oh.o_totalprice,
    cn.n_name,
    ps.total_available,
    ps.avg_supply_cost,
    so.total_sales
ORDER BY oh.o_orderdate DESC, so.total_sales DESC;
