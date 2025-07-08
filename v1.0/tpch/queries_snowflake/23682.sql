
WITH RECURSIVE CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, 
           o.o_totalprice, o.o_orderstatus, 0 AS Level
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '1996-01-01' AND o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT co.c_custkey, co.c_name, o.o_orderkey, o.o_orderdate, 
           o.o_totalprice, o.o_orderstatus, co.Level + 1
    FROM CustomerOrders co
    JOIN orders o ON co.c_custkey = o.o_custkey
    WHERE o.o_orderdate > co.o_orderdate AND co.Level < 5
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
FrequentParts AS (
    SELECT l.l_partkey, COUNT(*) AS OrderCount
    FROM lineitem l
    JOIN CustomerOrders co ON l.l_orderkey = co.o_orderkey
    WHERE l.l_returnflag = 'R'
    GROUP BY l.l_partkey
    HAVING COUNT(*) > 5
)
SELECT
    co.c_custkey,
    co.c_name,
    COUNT(DISTINCT co.o_orderkey) AS TotalOrders,
    SUM(co.o_totalprice) AS GrandTotal,
    LISTAGG(DISTINCT CONCAT('OrderID: ', co.o_orderkey, 
                             ', Date: ', co.o_orderdate), '; ') WITHIN GROUP (ORDER BY co.o_orderdate) AS OrderDetails,
    MAX(fp.OrderCount) AS MaxFrequentOrders,
    sd.TotalCost AS SupplierCost
FROM CustomerOrders co
LEFT JOIN FrequentParts fp ON co.o_orderkey IN (
    SELECT l.l_orderkey
    FROM lineitem l
    WHERE l.l_partkey = fp.l_partkey
)
LEFT JOIN SupplierDetails sd ON EXISTS (
    SELECT 1
    FROM partsupp ps
    WHERE ps.ps_partkey = fp.l_partkey
    AND ps.ps_suppkey = sd.s_suppkey
)
WHERE COALESCE(sd.TotalCost, 0) < (SELECT AVG(TotalCost) FROM SupplierDetails)
GROUP BY co.c_custkey, co.c_name, sd.TotalCost
HAVING SUM(co.o_totalprice) > 5000
ORDER BY GrandTotal DESC, TotalOrders DESC
LIMIT 10;
