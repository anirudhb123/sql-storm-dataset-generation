WITH RECURSIVE Nationwide_Supplier AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal 
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal 
    FROM supplier s
    JOIN Nationwide_Supplier ns ON s.s_nationkey = ns.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
Price_Analysis AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
Customer_Order_Summary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
High_Value_Customers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
    WHERE c.c_acctbal > 100000
),
Discounted_LineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS discounted_price
    FROM lineitem l
    WHERE l.l_discount > 0
    GROUP BY l.l_orderkey
)
SELECT 
    ns.s_name AS Supplier_Name,
    ns.s_acctbal AS Supplier_Balance,
    pa.p_name AS Part_Name,
    pa.total_supply_cost AS Total_Supply_Cost,
    cus.c_name AS Customer_Name,
    cus.total_orders AS Total_Orders,
    cus.total_spent AS Total_Spent,
    hvc.c_acctbal AS High_Value_Balance,
    dl.discounted_price AS Total_Discounted_Sales
FROM Nationwide_Supplier ns
FULL OUTER JOIN Price_Analysis pa ON ns.s_suppkey = pa.p_partkey
JOIN Customer_Order_Summary cus ON ns.s_nationkey = cus.c_custkey
LEFT JOIN High_Value_Customers hvc ON cus.c_custkey = hvc.c_custkey
FULL JOIN Discounted_LineItems dl ON cus.total_orders = dl.l_orderkey
WHERE ns.s_acctbal IS NOT NULL 
  AND (pa.total_supply_cost IS NULL OR pa.total_supply_cost > 5000)
  AND hvc.rank <= 10
ORDER BY ns.s_acctbal DESC, pa.total_supply_cost ASC;
