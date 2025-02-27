WITH RankedOrders AS (
    SELECT o_orderkey, o_custkey, o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_totalprice DESC) AS rnk
    FROM orders
    WHERE o_orderdate BETWEEN '2022-01-01' AND '2023-01-01' 
      AND o_totalprice IS NOT NULL
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    JOIN RankedOrders o ON c.c_custkey = o.o_custkey
    WHERE o.rnk <= 5
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
SupplierParts AS (
    SELECT s.s_suppkey, p.p_partkey, p.p_name, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal BETWEEN 1000.00 AND 5000.00
),
OrderLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_extendedprice, l.l_discount,
           CASE 
               WHEN l.l_discount = 0 THEN l.l_extendedprice
               ELSE l.l_extendedprice * (1 - l.l_discount)
           END AS FinalPrice
    FROM lineitem l
    WHERE l_returnflag = 'N'
),
CombinedData AS (
    SELECT h.c_custkey, h.c_name, sp.p_partkey, sp.p_name, sp.ps_supplycost, 
           SUM(ol.FinalPrice) AS TotalLineitemPrice
    FROM HighValueCustomers h
    LEFT JOIN SupplierParts sp ON sp.ps_supplycost < 200.00 
    LEFT JOIN OrderLineItems ol ON ol.l_orderkey IN (
        SELECT o_orderkey 
        FROM orders o 
        WHERE o.o_custkey = h.c_custkey
    )
    WHERE sp.p_partkey IS NOT NULL
    GROUP BY h.c_custkey, h.c_name, sp.p_partkey, sp.p_name, sp.ps_supplycost
)
SELECT c.c_custkey, c.c_name, COALESCE(CASE 
        WHEN cd.TotalLineitemPrice > 5000 THEN 'Gold'
        WHEN cd.TotalLineitemPrice BETWEEN 2000 AND 5000 THEN 'Silver'
        ELSE 'Bronze'
    END, 'No Orders') AS CustomerStatus,
    SUM(cd.ps_supplycost) AS TotalSupplyCost
FROM CombinedData cd
RIGHT JOIN HighValueCustomers c ON cd.c_custkey = c.c_custkey
GROUP BY c.c_custkey, c.c_name
ORDER BY TotalSupplyCost DESC, c.c_name ASC
LIMIT 10;
