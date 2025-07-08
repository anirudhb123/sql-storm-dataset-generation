
WITH RankedCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS Rank
    FROM customer c
),
NationParts AS (
    SELECT n.n_nationkey, n.n_name,
           COUNT(DISTINCT p.p_partkey) AS PartCount,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY n.n_nationkey, n.n_name
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalValue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_custkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
CustomerOrders AS (
    SELECT rc.c_custkey, rc.c_name, hvo.TotalValue
    FROM RankedCustomers rc
    JOIN HighValueOrders hvo ON rc.c_custkey = hvo.o_custkey
    WHERE rc.Rank <= 5
)
SELECT n.n_name, np.PartCount, np.TotalSupplyCost, COALESCE(SUM(co.TotalValue), 0) AS CustomerTotalValue
FROM NationParts np
JOIN nation n ON np.n_nationkey = n.n_nationkey
LEFT JOIN CustomerOrders co ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = co.c_custkey LIMIT 1)
GROUP BY n.n_name, np.PartCount, np.TotalSupplyCost
ORDER BY np.PartCount DESC, CustomerTotalValue DESC
LIMIT 10;
