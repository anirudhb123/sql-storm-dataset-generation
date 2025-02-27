WITH RECURSIVE CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2023-01-01'
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN CustomerOrders co ON co.c_custkey = c.c_custkey AND co.o_orderkey <> o.o_orderkey
    WHERE o.o_orderdate >= '2023-01-01'
),
RegionStats AS (
    SELECT r.r_regionkey, r.r_name,
           COUNT(DISTINCT n.n_nationkey) AS nation_count,
           SUM(o.o_totalprice) AS total_revenue
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY r.r_regionkey, r.r_name
),
SupplierAverageCost AS (
    SELECT ps.ps_partkey, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
HighValueOrders AS (
    SELECT co.c_custkey, co.o_orderkey, co.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY co.c_custkey ORDER BY co.o_totalprice DESC) AS order_rank
    FROM CustomerOrders co
    WHERE co.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
)
SELECT r.r_name, rs.nation_count, rs.total_revenue,
       SUM(CASE WHEN hvo.o_orderkey IS NOT NULL THEN hvo.o_totalprice ELSE 0 END) AS high_value_revenue,
       SUM(CASE WHEN p.p_partkey IS NULL THEN 1 ELSE 0 END) AS null_part_count
FROM RegionStats rs
FULL OUTER JOIN lineitem l ON rs.r_regionkey = 
    (SELECT n.n_regionkey 
     FROM nation n 
     INNER JOIN customer c ON n.n_nationkey = c.c_nationkey 
     WHERE c.c_custkey IN (SELECT DISTINCT co.c_custkey FROM HighValueOrders co))
LEFT JOIN partsupp p ON p.ps_partkey = l.l_partkey
LEFT JOIN HighValueOrders hvo ON hvo.o_orderkey = l.l_orderkey
GROUP BY r.r_name, rs.nation_count, rs.total_revenue
HAVING SUM(l.l_quantity) > 1000 OR rs.total_revenue IS NOT NULL
ORDER BY rs.total_revenue DESC;
