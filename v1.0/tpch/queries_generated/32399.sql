WITH RECURSIVE CTE_CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_totalprice > 1000
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN CTE_CustomerOrders cte ON c.c_custkey = cte.c_custkey
    WHERE o.o_orderdate < cte.o_orderdate
      AND o.o_orderstatus = 'O'
),
CTE_SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > 100
),
RankedParts AS (
    SELECT p.*, 
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS part_rank
    FROM part p
)
SELECT 
    cte.c_name AS Customer_Name,
    cte.o_orderkey AS Order_Key,
    cte.o_orderdate AS Order_Date,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS Total_Sales,
    STRING_AGG(DISTINCT s.s_name, ', ') AS Supplier_Names,
    CASE 
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) IS NULL THEN 'No Sales'
        ELSE 'Sales Present'
    END AS Sales_Status
FROM CTE_CustomerOrders cte
JOIN lineitem l ON cte.o_orderkey = l.l_orderkey
LEFT JOIN CTE_SupplierParts sp ON l.l_partkey = sp.p_partkey
INNER JOIN RankedParts rp ON l.l_partkey = rp.p_partkey AND rp.part_rank <= 5
GROUP BY cte.c_custkey, cte.c_name, cte.o_orderkey, cte.o_orderdate
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 0
ORDER BY Total_Sales DESC;
