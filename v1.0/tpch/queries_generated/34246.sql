WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, 
           SUM(ps.ps_availqty) AS total_avail_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_retailprice
),
OrderStatistics AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn,
           COUNT(*) OVER (PARTITION BY o.o_orderstatus) AS status_count
    FROM orders o
),
TopOrders AS (
    SELECT os.o_orderkey, os.o_totalprice
    FROM OrderStatistics os
    WHERE os.rn <= 10
)
SELECT 
    ph.p_partkey, 
    ph.p_name, 
    ph.p_brand, 
    COALESCE(oh.o_totalprice, 0) AS top_order_price,
    ph.total_avail_qty, 
    ph.avg_supply_cost,
    CASE 
        WHEN ph.p_retailprice < 50 THEN 'Low'
        WHEN ph.p_retailprice BETWEEN 50 AND 150 THEN 'Medium'
        ELSE 'High'
    END AS price_category,
    CASE 
        WHEN s.s_nationkey IS NULL THEN 'No Supplier'
        ELSE 'Supplier Exists'
    END AS supplier_status
FROM PartDetails ph
LEFT JOIN TopOrders oh ON ph.p_partkey = oh.o_orderkey
LEFT JOIN supplier s ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = ph.p_partkey)
LEFT JOIN region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = s.s_nationkey)
WHERE ph.total_avail_qty > 100
  AND ph.avg_supply_cost BETWEEN 10.00 AND 100.00
ORDER BY ph.p_retailprice DESC
LIMIT 50;
