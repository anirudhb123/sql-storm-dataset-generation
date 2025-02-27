WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_nationkey = sh.s_nationkey)
),
AggregatedOrders AS (
    SELECT 
        o.o_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_revenue,
        AVG(o.o_totalprice) AS avg_order_value
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE c.c_mktsegment = 'BUILDING'
    GROUP BY o.o_custkey
),
RankedLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_quantity,
        l.l_extendedprice,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS item_rank
    FROM lineitem l
    WHERE l.l_discount < 0.05 AND l.l_returnflag = 'N'
),
FinalSupplierData AS (
    SELECT 
        sh.s_suppkey,
        sh.s_name,
        COUNT(ll.l_orderkey) AS total_orders,
        SUM(ll.l_extendedprice * (1 - ll.l_discount)) AS total_sales,
        MAX(ll.l_shipdate) AS last_ship_date
    FROM SupplierHierarchy sh
    LEFT JOIN RankedLineItems ll ON sh.s_suppkey = ll.l_suppkey
    GROUP BY sh.s_suppkey, sh.s_name
),
FinalResults AS (
    SELECT 
        a.o_custkey,
        a.order_count,
        a.total_revenue,
        a.avg_order_value,
        fs.s_name,
        fs.total_orders,
        fs.total_sales,
        fs.last_ship_date
    FROM AggregatedOrders a
    LEFT JOIN FinalSupplierData fs ON a.o_custkey = fs.s_suppkey
)
SELECT 
    fr.o_custkey,
    fr.order_count,
    fr.total_revenue,
    fr.avg_order_value,
    COALESCE(fr.s_name, 'Unknown') AS supplier_name,
    COALESCE(fr.total_orders, 0) AS total_orders,
    COALESCE(fr.total_sales, 0.00) AS total_sales,
    CASE 
        WHEN fr.last_ship_date IS NULL THEN 'Never Shipped'
        ELSE fr.last_ship_date
    END AS last_ship_date
FROM FinalResults fr
WHERE fr.order_count > 10
ORDER BY fr.total_revenue DESC, fr.avg_order_value DESC
LIMIT 100;
