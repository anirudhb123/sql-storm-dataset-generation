WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_name LIKE '%land%'
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_regionkey
),
PartSupplierSummary AS (
    SELECT ps.ps_partkey, 
           SUM(ps.ps_availqty) AS total_availqty, 
           AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
CustomerOrderSummary AS (
    SELECT o.o_orderkey, 
           o.o_custkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01'
    GROUP BY o.o_orderkey, o.o_custkey
),
RankedOrders AS (
    SELECT coo.o_orderkey, 
           coo.o_custkey, 
           coo.total_revenue,
           RANK() OVER (PARTITION BY coo.o_custkey ORDER BY coo.total_revenue DESC) AS revenue_rank
    FROM CustomerOrderSummary coo
    WHERE coo.total_revenue IS NOT NULL
)
SELECT n.n_name AS nation_name,
       p.p_name AS part_name,
       ps.total_availqty,
       ps.avg_supplycost,
       ro.total_revenue,
       ro.revenue_rank
FROM PartSupplierSummary ps
JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN supplier s ON s.s_suppkey IN (SELECT ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = ps.ps_partkey)
LEFT JOIN RankedOrders ro ON ro.o_custkey IN (SELECT c.c_custkey 
                                                FROM customer c 
                                                WHERE c.c_nationkey = s.s_nationkey 
                                                  AND c.c_acctbal IS NOT NULL 
                                                  AND c.c_name IS NOT NULL)
JOIN nation n ON n.n_nationkey = s.s_nationkey
WHERE (p.p_retailprice * (1 - NULLIF(p.p_size, 0) / 100.0) > 0) 
  OR (ro.revenue_rank IS NULL AND ro.total_revenue < 10000)
ORDER BY n.n_name, total_revenue DESC;
