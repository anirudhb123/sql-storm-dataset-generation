WITH SupplierSummary AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           SUM(ps.ps_availqty) AS total_avail_qty, 
           AVG(ps.ps_supplycost) AS avg_supply_cost,
           COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT c.c_custkey,
           c.c_name,
           COUNT(o.o_orderkey) AS order_count,
           MAX(o.o_totalprice) AS max_order_total,
           MIN(o.o_orderdate) AS first_order_date,
           RANK() OVER (PARTITION BY c.c_custkey ORDER BY MAX(o.o_totalprice) DESC) AS order_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           ss.total_avail_qty,
           ss.avg_supply_cost,
           ROW_NUMBER() OVER (ORDER BY ss.total_avail_qty DESC) AS supplier_rank
    FROM SupplierSummary ss
    JOIN supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE ss.total_avail_qty > 100 
)
SELECT co.c_name AS CustomerName,
       co.order_count AS OrderCount,
       co.max_order_total AS MaxOrderAmount,
       ts.s_name AS SupplierName,
       ts.total_avail_qty AS SupplierTotalAvailability,
       ts.avg_supply_cost AS SupplierAverageCost
FROM CustomerOrders co
FULL OUTER JOIN TopSuppliers ts ON co.customer_rank <= 5 AND ts.supplier_rank <= 5
WHERE co.order_count IS NOT NULL OR ts.total_avail_qty IS NOT NULL
ORDER BY co.order_count DESC NULLS LAST, ts.total_avail_qty DESC NULLS LAST;
