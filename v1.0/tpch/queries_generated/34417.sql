WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderdate < CURRENT_DATE
),
SupplierPartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_mktsegment,
           COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey, c.c_name, c.c_mktsegment
),
RankedOrders AS (
    SELECT c.c_custkey, c.c_name,
           RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY co.total_spent DESC) AS spend_rank
    FROM CustomerOrders co
    JOIN customer c ON co.c_custkey = c.c_custkey
)
SELECT 
    r.r_name,
    np.n_name,
    SUM(lp.l_extendedprice * (1 - lp.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MAX(oh.level) AS max_order_level,
    MAX(spd.total_supply_cost) AS max_supply_cost
FROM region r
JOIN nation np ON r.r_regionkey = np.n_regionkey
LEFT JOIN supplier s ON np.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN lineitem lp ON lp.l_partkey = p.p_partkey
JOIN orders o ON o.o_orderkey = lp.l_orderkey
LEFT JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
JOIN SupplierPartDetails spd ON p.p_partkey = spd.p_partkey
GROUP BY r.r_name, np.n_name
HAVING SUM(lp.l_extendedprice * (1 - lp.l_discount)) > 10000
   AND COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_revenue DESC;
