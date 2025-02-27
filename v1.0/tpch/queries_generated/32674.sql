WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, CAST(o.o_orderkey AS VARCHAR(255)) AS hierarchy
    FROM orders o
    WHERE o.o_orderdate >= '2021-01-01'
    UNION ALL
    SELECT oh.o_orderkey, o.o_orderdate, o.o_totalprice, CAST(oh.hierarchy || ' -> ' || o.o_orderkey AS VARCHAR(255))
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey + 1
),
SupplierCosts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_supplycost) AS total_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
LineItemStats AS (
    SELECT l.l_orderkey, AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price,
           COUNT(case when l.l_returnflag = 'R' then 1 end) AS return_count
    FROM lineitem l
    GROUP BY l.l_orderkey
),
CustomerData AS (
    SELECT c.c_custkey, c.c_name, c.c_mktsegment,
           COALESCE(SUM(o.o_totalprice), 0) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_mktsegment
),
PartSuppliers AS (
    SELECT p.p_partkey, p.p_name, COALESCE(SUM(ps.ps_availqty), 0) AS total_available
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT cd.c_name, cd.c_mktsegment, oh.o_orderdate,
       ph.p_name, ph.total_available, lc.avg_price, 
       lc.return_count, sc.total_supplycost
FROM CustomerData cd
JOIN OrderHierarchy oh ON cd.total_spent > 5000
LEFT JOIN LineItemStats lc ON oh.o_orderkey = lc.l_orderkey
LEFT JOIN PartSuppliers ph ON lc.avg_price > 1000
LEFT JOIN SupplierCosts sc ON ph.p_partkey = sc.ps_partkey
WHERE cd.total_spent IS NOT NULL
ORDER BY cd.c_name, oh.o_orderdate DESC;
