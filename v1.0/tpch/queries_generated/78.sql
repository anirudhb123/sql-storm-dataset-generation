WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS Rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty, 
           (p.p_retailprice - ps.ps_supplycost) AS ProfitMargin,
           CASE 
               WHEN ps.ps_availqty < 10 THEN 'Low Inventory' 
               ELSE 'Sufficient Inventory' 
           END AS InventoryStatus
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS TotalOrders,
           SUM(o.o_totalprice) AS TotalSpent,
           AVG(o.o_totalprice) AS AvgOrderValue
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
FilteredCustomerOrder AS (
    SELECT cus.c_custkey, cus.c_name, sum(o.o_totalprice) AS TotalSpent, 
           ROW_NUMBER() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS OrderRank
    FROM customer cus
    LEFT JOIN orders o ON cus.c_custkey = o.o_custkey
    WHERE cus.c_acctbal IS NOT NULL AND cus.c_acctbal > 0
    GROUP BY cus.c_custkey, cus.c_name
    HAVING SUM(o.o_totalprice) > 1000
)
SELECT 
    p.p_name AS Part_Name,
    ps.InventoryStatus,
    rs.s_name AS Supplier_Name,
    SUM(o.o_totalprice) AS Total_Orders_Value,
    SUM(ls.l_extendedprice * (1 - ls.l_discount)) AS Net_Sales,
    ROW_NUMBER() OVER (PARTITION BY ps.p_partkey ORDER BY SUM(ls.l_extendedprice) DESC) AS SalesRank
FROM PartSupplierInfo ps
JOIN lineitem ls ON ps.p_partkey = ls.l_partkey
JOIN RankedSuppliers rs ON rs.s_suppkey = ls.l_suppkey
LEFT JOIN CustomerOrderSummary cus ON ls.l_orderkey = cus.TotalOrders
WHERE ps.ProfitMargin > 0 
AND ls.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY p.p_name, ps.InventoryStatus, rs.s_name
ORDER BY Total_Orders_Value DESC, Net_Sales ASC
LIMIT 50;
