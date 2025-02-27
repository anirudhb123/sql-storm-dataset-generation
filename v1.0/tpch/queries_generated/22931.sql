WITH HighlyRatedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_name IS NOT NULL
),
CompositeOrderValue AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey
),
NationPartCount AS (
    SELECT n.n_nationkey, COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_nationkey
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_orderdate,
           DENSE_RANK() OVER (ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate > CURRENT_DATE - INTERVAL '1 year'
)
SELECT r.r_name,
       COALESCE(NPC.part_count, 0) AS total_parts,
       HRS.s_name AS top_supplier,
       COV.total_value AS order_value,
       CASE 
           WHEN COV.total_value IS NULL THEN 'NO ORDERS'
           WHEN COV.total_value > 10000 THEN 'HIGH VALUE'
           ELSE 'LOW VALUE' 
       END AS order_value_category
FROM region r
LEFT JOIN NationPartCount NPC ON r.r_regionkey = NPC.n_nationkey
LEFT JOIN HighlyRatedSuppliers HRS ON HRS.rn = 1 
LEFT JOIN CompositeOrderValue COV ON COV.o_orderkey IN (
    SELECT o_orderkey FROM RecentOrders
) 
WHERE r.r_name LIKE 'E%' OR r.r_name IS NULL
ORDER BY r.r_name, total_parts DESC, COV.total_value;
