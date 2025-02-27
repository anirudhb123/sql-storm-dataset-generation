
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, sh.level + 1 AS level
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
PartSupplierSummary AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
FinalResults AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice,
           ps.total_supply_cost,
           os.order_total,
           CASE WHEN os.order_total IS NULL THEN 'No Orders' ELSE 'Orders Present' END AS order_status,
           RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    LEFT JOIN PartSupplierSummary ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN OrderSummary os ON os.o_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        JOIN customer c ON o.o_custkey = c.c_custkey 
        WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    )
)
SELECT DISTINCT f.p_partkey, f.p_name, f.p_brand, f.p_retailprice, f.total_supply_cost, f.order_total,
       f.order_status, f.price_rank, 
       COALESCE(r.r_name, 'Unknown') AS region_name
FROM FinalResults f
LEFT JOIN nation n ON n.n_nationkey = (
    SELECT s.s_nationkey 
    FROM supplier s 
    WHERE s.s_suppkey = f.p_partkey
)
LEFT JOIN region r ON r.r_regionkey = n.n_regionkey
WHERE (f.total_supply_cost IS NOT NULL OR f.order_total IS NOT NULL)
  AND (f.price_rank <= 10 OR f.order_total > 1000)
ORDER BY f.price_rank, f.p_retailprice DESC;
