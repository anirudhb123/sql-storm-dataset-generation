
WITH RankedSupplier AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS RNK
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL
),
AggregatedPart AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS Total_AvailQty,
           AVG(ps.ps_supplycost) AS Avg_SupplyCost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
FilteredOrder AS (
    SELECT o.o_orderkey, o.o_totalprice,
           CASE 
               WHEN o.o_orderstatus = 'F' THEN 'Finished'
               WHEN o.o_orderstatus = 'O' THEN 'Open'
               ELSE 'Other' 
           END AS Order_Status_Group
    FROM orders o
    WHERE o.o_orderdate > '1997-01-01'
)
SELECT r.r_name AS Region_Name,
       SUM(a.Total_AvailQty * l.l_extendedprice) AS Total_Value,
       COUNT(DISTINCT o.o_orderkey) AS Total_Orders,
       LISTAGG(CONCAT(s.s_name, ' (', s.s_acctbal, ')'), '; ') AS Supplier_Concat
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN RankedSupplier s ON n.n_nationkey = s.s_nationkey AND s.RNK <= 3
JOIN AggregatedPart a ON a.ps_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost < 100.00)
JOIN lineitem l ON l.l_partkey = a.ps_partkey
JOIN FilteredOrder o ON o.o_orderkey = l.l_orderkey
WHERE o.o_totalprice > 500.00 AND l.l_discount BETWEEN 0.1 AND 0.3
GROUP BY r.r_name
ORDER BY Total_Value DESC;
