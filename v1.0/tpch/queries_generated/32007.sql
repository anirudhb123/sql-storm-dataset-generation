WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS Level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, Level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_totalprice > oh.o_totalprice
),
SupplierWithParts AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
OrderLineDetails AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey, l.l_quantity, l.l_extendedprice, 
           (l.l_extendedprice * (1 - l.l_discount)) AS NetPrice,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS LineNumber
    FROM lineitem l
    WHERE l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
)
SELECT 
    oh.o_orderkey,
    COUNT(DISTINCT ol.LineNumber) AS TotalLineItems,
    SUM(ol.NetPrice) AS TotalNetPrice,
    AVG(sp.ps_supplycost) AS AverageSupplyCost,
    RANK() OVER (ORDER BY SUM(ol.NetPrice) DESC) AS OrderRank,
    CASE 
        WHEN AVG(sp.ps_supplycost) IS NULL THEN 'No Data' 
        ELSE 'Data Available' 
    END AS SupplyCostStatus
FROM OrderHierarchy oh
LEFT JOIN OrderLineDetails ol ON oh.o_orderkey = ol.l_orderkey
LEFT JOIN SupplierWithParts sp ON ol.l_partkey = sp.p_partkey
GROUP BY oh.o_orderkey
HAVING SUM(ol.NetPrice) > 1000 AND COUNT(DISTINCT ol.LineNumber) > 1
ORDER BY OrderRank
LIMIT 10;
