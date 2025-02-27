WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           REPLACE(UPPER(s.s_name), 'SUPPLIER', '') AS CleanedName,
           LENGTH(s.s_comment) AS CommentLength
    FROM supplier s
),
PartSupplierDetails AS (
    SELECT ps.ps_partkey, ps.ps_supkey, ps.ps_availqty, ps.ps_supplycost, 
           CONCAT('Total Cost: ', FORMAT(ps.ps_availqty * ps.ps_supplycost, 2)) AS TotalCost
    FROM partsupp ps
),
CustomerDetails AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           POSITION('VIP' IN c.c_comment) AS IsVIP,
           LEFT(c.c_address, 20) AS ShortAddress
    FROM customer c
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice,
           DATE_PART('year', o.o_orderdate) AS OrderYear,
           CASE 
              WHEN o.o_totalprice > 1000 THEN 'High Value'
              ELSE 'Low Value'
           END AS OrderValueCategory
    FROM orders o
)
SELECT 
    r.r_name AS RegionName,
    n.n_name AS NationName,
    COUNT(DISTINCT s.s_suppkey) AS SupplierCount,
    SUM(ps.ps_availqty) AS TotalAvailableQuantity,
    AVG(c.c_acctbal) AS AverageCustomerBalance,
    SUM(CASE WHEN o.o_totalprice > 1000 THEN 1 ELSE 0 END) AS HighValueOrderCount,
    STRING_AGG(DISTINCT pd.CleanedName, ', ') AS UniqueSupplierNames,
    MAX(pd.CommentLength) AS MaxCommentLength
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN CustomerDetails c ON c.c_nationkey = n.n_nationkey
JOIN OrderDetails o ON o.o_custkey = c.c_custkey
JOIN SupplierDetails pd ON pd.s_suppkey = s.s_suppkey
GROUP BY r.r_name, n.n_name
ORDER BY r.r_name, n.n_name;
