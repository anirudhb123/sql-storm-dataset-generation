WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderstatus, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus
),
CriticalSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(total_cost) FROM 
                (SELECT SUM(ps_supplycost * ps_availqty) AS total_cost
                 FROM partsupp
                 GROUP BY ps_suppkey) AS avg_cost)
)
SELECT 
    ph.s_suppkey AS Supplier_ID,
    ph.s_name AS Supplier_Name,
    COALESCE(os.total_revenue, 0) AS Total_Revenue,
    ch.total_cost AS Total_Cost,
    CASE 
        WHEN os.o_orderstatus = 'F' THEN 'Finished'
        WHEN os.o_orderstatus = 'P' THEN 'Pending'
        ELSE 'Other'
    END AS Order_Status_Description
FROM SupplierHierarchy ph
LEFT JOIN OrderSummary os ON ph.s_suppkey = os.o_orderkey
JOIN CriticalSuppliers ch ON ph.s_suppkey = ch.s_suppkey
WHERE ph.level < 3
ORDER BY Total_Revenue DESC, Total_Cost ASC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
