WITH RECURSIVE TopRegions AS (
    SELECT r_name, r_regionkey, 1 AS level
    FROM region
    WHERE r_name LIKE 'A%'
    UNION ALL
    SELECT r.r_name, r.r_regionkey, tr.level + 1
    FROM region r
    JOIN TopRegions tr ON r.r_regionkey = tr.r_regionkey
),
CustomerMetrics AS (
    SELECT c.c_custkey, c.c_name,
           SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierPartInfo AS (
    SELECT s.s_suppkey, s.s_name, 
           SUM(ps.ps_availqty) AS total_avail_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
RankedLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey, 
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS rank
    FROM lineitem l
    WHERE l.l_discount > 0.1 AND l.l_returnflag = 'N'
),
FinalReport AS (
    SELECT tr.r_name AS region_name, 
           cm.c_name AS customer_name,
           sp.total_avail_qty, 
           sp.avg_supply_cost,
           COUNT(li.l_orderkey) AS order_item_count
    FROM TopRegions tr
    JOIN CustomerMetrics cm ON cm.total_spent > 5000
    LEFT JOIN SupplierPartInfo sp ON sp.avg_supply_cost < 200
    LEFT JOIN RankedLineItems li ON li.l_suppkey = sp.s_suppkey
    GROUP BY tr.r_name, cm.c_name, sp.total_avail_qty, sp.avg_supply_cost
    HAVING COUNT(li.l_orderkey) > 5
)
SELECT *
FROM FinalReport
ORDER BY region_name, total_avail_qty DESC, customer_name;
