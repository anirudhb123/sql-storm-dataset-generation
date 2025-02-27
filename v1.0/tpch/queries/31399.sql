WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'  
    UNION ALL
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE oh.level < 5  
),
SupplierSummary AS (
    SELECT ps.ps_partkey, 
           SUM(ps.ps_availqty) AS total_available_qty,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
LineItemStats AS (
    SELECT 
        l.l_orderkey,
        COUNT(*) AS item_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        AVG(l.l_quantity) AS avg_quantity,
        MAX(l.l_receiptdate) AS latest_receipt
    FROM lineitem l
    GROUP BY l.l_orderkey
),
RegionCustomer AS (
    SELECT c.c_custkey, 
           r.r_name AS region_name,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, r.r_name
),
FinalReport AS (
    SELECT oh.o_orderkey,
           oh.o_orderdate,
           oh.o_totalprice,
           ls.item_count,
           ls.total_sales,
           rc.region_name,
           CASE 
               WHEN rc.total_spent IS NULL THEN 'No Spending Yet'
               ELSE 'Customer Active'
           END AS customer_status
    FROM OrderHierarchy oh
    LEFT JOIN LineItemStats ls ON oh.o_orderkey = ls.l_orderkey
    LEFT JOIN RegionCustomer rc ON rc.c_custkey = oh.o_orderkey
)
SELECT 
    fr.o_orderkey,
    fr.o_orderdate,
    fr.o_totalprice,
    fr.item_count,
    fr.total_sales,
    fr.region_name,
    fr.customer_status
FROM FinalReport fr
WHERE fr.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)  
ORDER BY fr.o_orderdate DESC, fr.total_sales DESC
LIMIT 100;