WITH RECURSIVE RegionCounts AS (
    SELECT r.r_regionkey, COUNT(n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey
),
CustomerOrders AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    INNER JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey
),
OrderDetails AS (
    SELECT o.o_orderkey, l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N' AND l.l_shipdate < CURRENT_DATE
    GROUP BY o.o_orderkey, l.l_partkey
),
SupplierCost AS (
    SELECT ps.ps_partkey, AVG(ps.ps_supplycost) AS avg_supply_cost, SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(rc.nation_count, 0) AS nation_count,
    COALESCE(co.total_spent, 0) AS customer_spending,
    COALESCE(od.revenue, 0) AS order_revenue,
    sc.avg_supply_cost,
    CASE 
        WHEN sc.total_available IS NULL THEN 'No Supply'
        WHEN sc.total_available < 100 THEN 'Low Supply'
        ELSE 'Adequate Supply'
    END AS supply_status,
    CASE 
        WHEN p.p_retailprice IS NULL OR p.p_retailprice <= 0 THEN 'Invalid Price'
        ELSE 'Valid Price'
    END AS retail_status
FROM part p
LEFT JOIN RegionCounts rc ON rc.r_regionkey = (
    SELECT n.n_regionkey
    FROM nation n
    WHERE n.n_nationkey = (
        SELECT n2.n_nationkey
        FROM supplier s
        JOIN nation n2 ON s.s_nationkey = n2.n_nationkey
        WHERE EXISTS (
            SELECT 1
            FROM CustomerOrders co
            WHERE co.total_spent > 1000
            AND co.c_custkey = s.s_suppkey
        )
        LIMIT 1
    )
)
LEFT JOIN CustomerOrders co ON co.c_custkey = (
    SELECT c.c_custkey
    FROM customer c
    WHERE c.c_nationkey = (
        SELECT n.n_nationkey
        FROM supplier s
        JOIN nation n ON s.s_nationkey = n.n_nationkey
        LIMIT 1
    )
)
LEFT JOIN OrderDetails od ON od.l_partkey = p.p_partkey
LEFT JOIN SupplierCost sc ON sc.ps_partkey = p.p_partkey
WHERE (p.p_size = 0 OR p.p_size IS NULL OR p.p_size BETWEEN 1 AND 100)
  AND (rc.nation_count IS NOT NULL OR p.p_mfgr IN ('Manufacturer#1', 'Manufacturer#2'))
  AND NOT EXISTS (
      SELECT 1
      FROM partsupp ps
      WHERE ps.ps_partkey = p.p_partkey AND ps.ps_supplycost > 100
  )
ORDER BY p.p_partkey DESC;
