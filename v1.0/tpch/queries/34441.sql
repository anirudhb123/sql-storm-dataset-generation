WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_suppkey = (SELECT MIN(s_suppkey) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
TopCustomerOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_name, RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O'
),
PartStats AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
RecentHighVolumeOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= cast('1998-10-01' as date) - INTERVAL '30 days'
    GROUP BY o.o_orderkey
)
SELECT 
    sh.s_name AS supplier_name,
    ch.c_name AS customer_name,
    ps.p_name AS part_name,
    oh.total_revenue AS order_revenue,
    ps.total_available,
    ps.avg_supply_cost,
    ch.rank AS customer_rank,
    'Region: ' || r.r_name AS customer_region,
    CASE 
        WHEN ps.total_available IS NULL THEN 'Out of Stock'
        ELSE 'In Stock'
    END AS availability_status
FROM SupplierHierarchy sh
LEFT JOIN nation n ON sh.s_nationkey = n.n_nationkey
LEFT JOIN TopCustomerOrders ch ON ch.rank <= 10
JOIN PartStats ps ON sh.s_suppkey = (SELECT ps2.ps_suppkey FROM partsupp ps2 WHERE ps2.ps_partkey = ps.p_partkey ORDER BY ps2.ps_supplycost DESC LIMIT 1)
JOIN RecentHighVolumeOrders oh ON oh.o_orderkey = (SELECT MIN(o2.o_orderkey) FROM orders o2 WHERE o2.o_totalprice > 1000)
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE (sh.level IS NOT NULL OR ps.total_available IS NOT NULL)
ORDER BY oh.total_revenue DESC, sh.s_name;