WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 3
),
PartSuppliers AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
MaxOrders AS (
    SELECT o.o_orderkey, MAX(o.o_totalprice) AS max_total_price
    FROM orders o
    GROUP BY o.o_orderkey
),
PartSales AS (
    SELECT l.l_partkey, COUNT(l.l_orderkey) AS sale_count, AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_sales
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY l.l_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_size,
    ps.total_avail_qty,
    ps.avg_supply_cost,
    s.s_name,
    COALESCE(s.s_acctbal, 0) AS supplier_balance,
    sales.sale_count,
    sales.avg_sales,
    mo.max_total_price
FROM 
    part p
LEFT JOIN PartSuppliers ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_partkey = s.s_nationkey
LEFT JOIN PartSales sales ON p.p_partkey = sales.l_partkey
LEFT JOIN MaxOrders mo ON mo.o_orderkey = (SELECT MAX(o.o_orderkey) FROM orders o WHERE o.o_orderkey IS NOT NULL)
WHERE 
    p.p_retailprice > 100.00
    AND (s.s_acctbal IS NULL OR s.s_acctbal >= 500)
ORDER BY 
    p.p_partkey, sales.sale_count DESC;