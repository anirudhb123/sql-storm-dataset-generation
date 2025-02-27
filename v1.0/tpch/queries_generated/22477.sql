WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 1 AS level
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
    UNION ALL
    SELECT ch.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM CustomerHierarchy ch
    JOIN customer c ON c.c_nationkey = ch.c_nationkey
    WHERE ch.level < 5
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= DATEADD(month, -6, CURRENT_DATE)
),
SupplierPartInfo AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, 
           SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    WHERE ps.ps_supplycost < (SELECT AVG(ps2.ps_supplycost) FROM partsupp ps2)
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
FilteredLineItems AS (
    SELECT li.l_orderkey, li.l_partkey, li.l_suppkey, li.l_quantity,
           (li.l_extendedprice * (1 - li.l_discount)) AS net_price,
           ROW_NUMBER() OVER (PARTITION BY li.l_orderkey ORDER BY li.l_linenumber) AS item_rank
    FROM lineitem li
    WHERE li.l_quantity BETWEEN 10 AND 100
      AND li.l_returnflag = 'N'
)
SELECT 
    ch.c_name, 
    ch.level AS customer_level, 
    ro.o_totalprice,
    COALESCE(sp.avg_supply_cost, 0) AS average_supply_cost,
    SUM(fli.net_price) AS total_net_price
FROM CustomerHierarchy ch
LEFT JOIN RecentOrders ro ON ch.c_custkey = ro.o_custkey
LEFT JOIN SupplierPartInfo sp ON sp.ps_partkey IN (SELECT l_partkey FROM lineitem WHERE l_orderkey = ro.o_orderkey)
LEFT JOIN FilteredLineItems fli ON fli.l_orderkey = ro.o_orderkey
WHERE ch.c_nationkey IS NOT NULL
GROUP BY ch.c_name, ch.level, ro.o_totalprice, sp.avg_supply_cost
HAVING SUM(fli.net_price) IS NOT NULL
   AND ro.o_totalprice > 500
ORDER BY customer_level DESC, total_net_price DESC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
