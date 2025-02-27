WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, p.p_brand
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 100
),
AggCustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    r.r_name AS Region_Name,
    COUNT(DISTINCT n.n_nationkey) AS Nation_Count,
    AVG(a.total_spent) AS Avg_Spent,
    COUNT(DISTINCT h.p_partkey) AS High_Value_Part_Count,
    SUM(s.total_supplycost) AS Total_Supply_Cost
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN AggCustomerOrders a ON n.n_nationkey = a.c_custkey
JOIN HighValueParts h ON h.p_partkey IN (
    SELECT ps.ps_partkey 
    FROM partsupp ps 
    WHERE ps.ps_availqty > 50
)
JOIN RankedSuppliers s ON h.p_partkey IN (
    SELECT ps.ps_partkey 
    FROM partsupp ps 
    WHERE ps.ps_supplycost > 20
)
GROUP BY r.r_name
ORDER BY Total_Supply_Cost DESC
LIMIT 10;
