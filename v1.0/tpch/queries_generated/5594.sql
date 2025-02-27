WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, COUNT(o.o_orderkey) AS TotalOrders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
),
OrderLineItems AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalLineItemValue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
)
SELECT
    cs.c_custkey,
    cs.c_name,
    rs.s_suppkey,
    rs.s_name,
    rs.TotalSupplyCost,
    coalesce(SUM(oli.TotalLineItemValue), 0) AS TotalOrderValue,
    cs.TotalOrders,
    cs.c_acctbal
FROM CustomerOrders cs
JOIN RankedSuppliers rs ON cs.TotalOrders > 5
LEFT JOIN OrderLineItems oli ON cs.c_custkey = oli.o_orderkey
WHERE rs.TotalSupplyCost > 10000
GROUP BY cs.c_custkey, cs.c_name, rs.s_suppkey, rs.s_name, rs.TotalSupplyCost, cs.TotalOrders, cs.c_acctbal
ORDER BY TotalOrderValue DESC, cs.c_acctbal ASC;
