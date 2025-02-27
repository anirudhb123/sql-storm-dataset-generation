WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_nationkey, c.c_mktsegment, 0 AS level
    FROM customer c
    WHERE c.c_acctbal > 5000

    UNION ALL

    SELECT ch.c_custkey, ch.c_name, ch.c_acctbal * 0.9, ch.c_nationkey, ch.c_mktsegment, ch.level + 1
    FROM CustomerHierarchy ch
    WHERE ch.level < 5
), 
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_avail_qty, AVG(s.s_acctbal) AS avg_acctbal
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), 
RecentOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderstatus, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '30 days'
), 
RankedLineItems AS (
    SELECT l.*, 
           RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS price_rank
    FROM lineitem l
)

SELECT 
    c.c_name AS Customer_Name,
    COALESCE(ss.total_avail_qty, 0) AS Total_Avail_Qty,
    c.c_acctbal AS Customer_Account_Balance,
    r.o_totalprice AS Recent_Order_Total_Price,
    CASE 
        WHEN r.o_orderstatus = 'O' THEN 'Open'
        ELSE 'Closed' 
    END AS Order_Status,
    p.p_name AS Part_Name,
    COUNT(li.l_linenumber) AS Line_Item_Count,
    MAX(li.l_discount) AS Max_Discount
FROM 
    CustomerHierarchy c
LEFT JOIN 
    RecentOrders r ON c.c_custkey = r.o_custkey
LEFT JOIN 
    SupplierStats ss ON ss.avg_acctbal < c.c_acctbal
LEFT JOIN 
    RankedLineItems li ON r.o_orderkey = li.l_orderkey
LEFT JOIN 
    part p ON li.l_partkey = p.p_partkey
WHERE 
    c.c_mktsegment = 'BUILDING'
    AND (ss.total_avail_qty IS NULL OR ss.total_avail_qty > 100)
GROUP BY 
    c.c_name, ss.total_avail_qty, c.c_acctbal, r.o_totalprice, r.o_orderstatus, p.p_name
HAVING 
    COUNT(li.l_linenumber) > 0
ORDER BY 
    c.c_name, r.o_totalprice DESC;
