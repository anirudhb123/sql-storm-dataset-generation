WITH RankedSuppliers AS (
    SELECT s_suppkey, s_name, s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY n_regionkey ORDER BY s_acctbal DESC) AS rank,
           COUNT(*) OVER (PARTITION BY n_regionkey) AS total_suppliers
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s_acctbal IS NOT NULL
), MaxOrderValue AS (
    SELECT o_custkey, MAX(o_totalprice) AS max_order
    FROM orders
    GROUP BY o_custkey
), NullHandledLineItems AS (
    SELECT l.*, 
           CASE 
               WHEN l_discount IS NULL THEN 0 
               ELSE l_discount 
           END AS handled_discount,
           COALESCE(NULLIF(l_tax, 0), 1) AS effective_tax, 
           CASE 
               WHEN l_shipdate < o_orderdate THEN 'Delayed'
               ELSE 'On Time'
           END AS shipment_status
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
), FinalSupplierData AS (
    SELECT r.r_name AS region_name, 
           r.r_comment AS region_comment,
           s.s_name AS supplier_name,
           AVG(ps_supplycost) AS avg_supply_cost,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM RankedSuppliers s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN nation n ON s.suppkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN MaxOrderValue mov ON s.s_suppkey = mov.o_custkey
    GROUP BY r.r_name, r.r_comment, s.s_name
    HAVING AVG(ps_supplycost) > (SELECT AVG(ps_supplycost) * 1.1 FROM partsupp)
       AND COUNT(DISTINCT o.o_orderkey) > 10
    ORDER BY r.r_name, s.s_name
), SumOrders AS (
    SELECT c.c_custkey, SUM(mo.max_order) AS total_max_order
    FROM MaxOrderValue mo
    JOIN customer c ON mo.o_custkey = c.c_custkey
    GROUP BY c.c_custkey
), CombinedData AS (
    SELECT fd.*, sod.total_max_order
    FROM FinalSupplierData fd
    LEFT JOIN SumOrders sod ON fd.s_name = sod.c_custkey
)
SELECT fd.region_name, fd.supplier_name, 
       CONCAT('Region: ', fd.region_name, ' | Supplier: ', fd.supplier_name, ' | Average Supply Cost: ', ROUND(fd.avg_supply_cost, 2)) AS details,
       COALESCE(fd.total_max_order, 0) AS last_max_order_value
FROM CombinedData fd
WHERE fd.avg_supply_cost IS NOT NULL
  AND (fd.total_max_order IS NULL OR fd.total_max_order > 500)
ORDER BY region_name, supplier_name;
