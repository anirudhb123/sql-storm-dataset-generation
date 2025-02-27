WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS Level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.Level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.Level < 5
),
TotalLineItemValue AS (
    SELECT l_orderkey, SUM(l_extendedprice * (1 - l_discount)) AS TotalValue
    FROM lineitem
    GROUP BY l_orderkey
),
CustomerOrderDetails AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
),
FilteredCustomerOrders AS (
    SELECT cust.c_custkey, cust.c_name, ord.o_orderkey, ord.o_totalprice, ord.o_orderdate
    FROM CustomerOrderDetails ord
    JOIN customer cust ON ord.c_custkey = cust.c_custkey
    WHERE ord.rn <= 3
)
SELECT 
    supp.s_name AS SupplierName,
    supp.s_acctbal AS SupplierAccountBalance,
    COUNT(DISTINCT loc.uid) AS NumberOfUniqueLifelines,
    SUM(COALESCE(tlv.TotalValue, 0)) AS TotalLineItemValue,
    MAX(COALESCE(co.o_totalprice, 0)) AS MaximumOrderTotal
FROM SupplierHierarchy supp
LEFT JOIN (
    SELECT DISTINCT l.l_suppkey AS uid, l.l_orderkey
    FROM lineitem l
) loc ON supp.s_suppkey = loc.uid
LEFT JOIN TotalLineItemValue tlv ON loc.l_orderkey = tlv.l_orderkey
LEFT JOIN FilteredCustomerOrders co ON co.o_orderkey = loc.l_orderkey
GROUP BY supp.s_suppkey, supp.s_name, supp.s_acctbal
HAVING MAX(co.o_totalprice) > 1000
ORDER BY NumberOfUniqueLifelines DESC, SupplierName;
