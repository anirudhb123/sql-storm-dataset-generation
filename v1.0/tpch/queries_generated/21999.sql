WITH RECURSIVE Recursive_CTE AS (
    SELECT n_nationkey, n_name, n_regionkey, n_comment
    FROM nation
    WHERE n_nationkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, n.n_comment
    FROM nation n
    JOIN Recursive_CTE r ON n.n_regionkey = r.n_regionkey
), Supplier_Summary AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           SUM(ps.ps_supplycost) AS Total_Supply_Cost,
           COUNT(DISTINCT ps.ps_partkey) AS Unique_Parts_Supplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), Customer_Sales AS (
    SELECT c.c_custkey, 
           c.c_name,
           SUM(o.o_totalprice) AS Total_Orders,
           COUNT(DISTINCT o.o_orderkey) AS Order_Count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), Lineitem_Analysis AS (
    SELECT l.l_orderkey,
           AVG(l.l_discount) AS Avg_Discount,
           SUM(l.l_extendedprice) OVER (PARTITION BY l.l_orderkey) AS Total_Extended_Price,
           COUNT(*) AS Line_Item_Count
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT r.r_name, 
       s.s_name, 
       cs.c_name, 
       SUM(su.Total_Supply_Cost) AS Total_Supplies,
       SUM(cs.Total_Orders) AS Total_Sales,
       SUM(CASE WHEN la.Line_Item_Count > 5 THEN la.Total_Extended_Price ELSE 0 END) AS Total_High_Count_Lineitems
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN Supplier_Summary su ON n.n_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_nationkey = su.s_suppkey)
LEFT JOIN Customer_Sales cs ON n.n_nationkey = cs.c_custkey
LEFT JOIN Lineitem_Analysis la ON cs.c_custkey = la.l_orderkey
GROUP BY r.r_name, s.s_name, cs.c_name
HAVING SUM(su.Total_Supply_Cost) IS NOT NULL 
   OR SUM(cs.Total_Orders) IS NULL 
   OR COUNT(DISTINCT r.r_regionkey) = 1
ORDER BY Total_High_Count_Lineitems DESC, Total_Sales ASC NULLS LAST;
