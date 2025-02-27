WITH SupplierParts AS (
    SELECT ps.ps_partkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY c.c_custkey, c.c_name
),
LineItemSummary AS (
    SELECT l.l_partkey, COUNT(*) AS LineItemCount, AVG(l.l_discount) AS AvgDiscount
    FROM lineitem l
    WHERE l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
    GROUP BY l.l_partkey
)
SELECT p.p_name, p.p_mfgr, sp.TotalSupplyCost, co.TotalSpent, lis.LineItemCount, lis.AvgDiscount
FROM part p
LEFT JOIN SupplierParts sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN CustomerOrders co ON co.c_custkey IN (
    SELECT c.c_custkey
    FROM customer c
    WHERE c.c_acctbal > 1000
)
LEFT JOIN LineItemSummary lis ON p.p_partkey = lis.l_partkey
WHERE p.p_size BETWEEN 10 AND 20
ORDER BY TotalSupplyCost DESC, TotalSpent DESC, p.p_name
LIMIT 100;
