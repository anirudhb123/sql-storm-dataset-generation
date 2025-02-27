WITH RECURSIVE RegionNations AS (
    SELECT r_name, n_name, n_regionkey
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    WHERE r_name LIKE 'S%'
    UNION ALL
    SELECT r.r_name, n.n_name, n.n_regionkey
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN RegionNations rn ON rn.n_regionkey = n.n_regionkey
    WHERE n.n_name <> rn.n_name
),
SupplierStats AS (
    SELECT s.s_suppkey, 
           s.s_name,
           COUNT(ps.ps_partkey) AS supply_count,
           AVG(ps.ps_supplycost) AS avg_supply_cost,
           SUM(ps.ps_availqty) AS total_avail_qty
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueOrders AS (
    SELECT o.o_orderkey,
           o.o_custkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
CustomerRank AS (
    SELECT c.c_custkey, 
           c.c_name,
           RANK() OVER (ORDER BY c.c_acctbal DESC) AS customer_rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
)
SELECT rn.r_name,
       rn.n_name,
       ss.s_name,
       COALESCE(hv.order_value, 0) AS highest_order_value,
       cr.customer_rank,
       CUBE(ss.supply_count) AS supply_cube
FROM RegionNations rn
FULL OUTER JOIN SupplierStats ss ON ss.supply_count < 10 
LEFT JOIN HighValueOrders hv ON hv.o_custkey = ss.s_suppkey
LEFT JOIN CustomerRank cr ON cr.c_custkey = ss.s_suppkey
WHERE (rn.n_name IS NOT NULL OR ss.s_name IS NULL)
  AND (hv.order_value IS NULL OR cr.customer_rank < 5)
ORDER BY rn.r_name, ss.s_name DESC, highest_order_value DESC;
