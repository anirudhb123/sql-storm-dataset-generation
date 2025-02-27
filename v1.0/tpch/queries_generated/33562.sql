WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS level
    FROM orders
    WHERE o_orderdate >= '2022-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey > oh.o_orderkey
    WHERE oh.level < 10
),
HighValueOrders AS (
    SELECT oh.o_orderkey, oh.o_totalprice, c.c_mktsegment,
           RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY oh.o_totalprice DESC) AS price_rank
    FROM OrderHierarchy oh
    JOIN customer c ON oh.o_custkey = c.c_custkey
    WHERE oh.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
),
PartSupplierDetails AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_supplycost,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
PartSales AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN HighValueOrders hvo ON l.l_orderkey = hvo.o_orderkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count,
       COALESCE(SUM(ps.total_supplycost), 0) AS total_supply_cost,
       COALESCE(SUM(psd.total_sales), 0) AS total_part_sales
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN PartSupplierDetails ps ON n.n_nationkey = ps.ps_partkey
LEFT JOIN PartSales psd ON ps.ps_partkey = psd.p_partkey
GROUP BY r.r_name
HAVING COUNT(DISTINCT n.n_nationkey) > 1
ORDER BY r.r_name;
