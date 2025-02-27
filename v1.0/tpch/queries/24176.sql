WITH RankedOrders AS (
    SELECT 
        o_orderkey,
        o_custkey,
        o_orderdate,
        o_totalprice,
        RANK() OVER (PARTITION BY o_custkey ORDER BY o_orderdate DESC) AS order_rank
    FROM orders
    WHERE o_orderstatus = 'F'
), 
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        ps.ps_partkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS lowest_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL
),
CustomerRegions AS (
    SELECT 
        c.c_custkey,
        n.n_regionkey,
        r.r_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, n.n_regionkey, r.r_name
)

SELECT 
    cr.r_name,
    SUM(lp.l_extendedprice * (1 - lp.l_discount)) AS revenue,
    COUNT(DISTINCT cr.c_custkey) AS distinct_customers,
    (SELECT AVG(total_spend) FROM (
        SELECT SUM(o.o_totalprice) AS total_spend
        FROM orders o
        WHERE o.o_orderkey IN (SELECT o_orderkey FROM RankedOrders WHERE order_rank <= 5)
        GROUP BY o.o_custkey
    ) AS spends) AS average_spending,
    sp.ps_availqty
FROM lineitem lp
JOIN RankedOrders ro ON lp.l_orderkey = ro.o_orderkey
JOIN CustomerRegions cr ON cr.c_custkey = ro.o_custkey
LEFT JOIN SupplierParts sp ON sp.ps_partkey = lp.l_partkey AND sp.lowest_supply_cost = 1
WHERE cr.order_count IS NOT NULL
  AND cr.r_name NOT LIKE '%North%'
  AND EXISTS (
      SELECT 1 
      FROM SupplierParts sp2
      WHERE sp2.ps_partkey = lp.l_partkey
      AND sp2.ps_supplycost > (SELECT AVG(ps_supplycost) FROM SupplierParts WHERE ps_partkey = lp.l_partkey)
  )
GROUP BY cr.r_name, sp.ps_availqty
ORDER BY revenue DESC
LIMIT 10;
