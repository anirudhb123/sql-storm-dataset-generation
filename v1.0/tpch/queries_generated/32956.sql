WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s2.s_suppkey, s2.s_name, s2.s_acctbal, sh.level + 1
    FROM supplier s2
    JOIN SupplierHierarchy sh ON s2.s_suppkey = sh.s_suppkey
    WHERE sh.level < 5 
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_orderstatus = 'O' AND o.o_totalprice > (
        SELECT AVG(o2.o_totalprice)
        FROM orders o2
        WHERE o2.o_orderdate >= DATE '2023-01-01'
    )
),
MaxLineItems AS (
    SELECT l.l_orderkey, COUNT(*) AS lineitem_count
    FROM lineitem l
    GROUP BY l.l_orderkey
),
JoinSuppliers AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON p.p_partkey = ps.ps_partkey
    WHERE s.s_acctbal IS NOT NULL
)
SELECT COALESCE(rn.row_num, 'No Orders') AS Order_Rank,
       j.s_name AS Supplier_Name,
       j.p_name AS Part_Name,
       j.ps_availqty AS Available_Quantity,
       lm.lineitem_count AS Line_Item_Count,
       SUM(j.ps_supplycost * j.ps_availqty) AS Total_Cost
FROM RankedOrders rn
FULL OUTER JOIN JoinSuppliers j ON rn.o_orderkey = j.ps_partkey
LEFT JOIN MaxLineItems lm ON lm.l_orderkey = rn.o_orderkey
WHERE (j.ps_supplycost IS NOT NULL OR j.ps_availqty IS NULL)
GROUP BY rn.row_num, j.s_name, j.p_name, j.ps_availqty, lm.lineitem_count
HAVING SUM(j.ps_supplycost * j.ps_availqty) > 5000
ORDER BY Total_Cost DESC, Supplier_Name;
