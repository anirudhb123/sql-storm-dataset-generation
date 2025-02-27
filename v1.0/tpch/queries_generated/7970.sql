WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01'
),
SuppliersWithCost AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * l.l_quantity) AS TotalSupplyCost
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(c.c_acctbal) AS TotalAccountBalance
    FROM supplier s
    JOIN customer c ON s.s_nationkey = c.c_nationkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY TotalAccountBalance DESC
    LIMIT 10
)

SELECT 
    r.r_name,
    COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
    AVG(l.l_extendedprice) AS AvgExtendedPrice,
    SUM(c.c_acctbal) AS TotalCustomerBalance,
    ts.s_name AS SupplierName,
    ts.TotalAccountBalance
FROM RankedOrders o
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN SuppliersWithCost swc ON l.l_suppkey = swc.ps_suppkey
JOIN TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE o.o_orderstatus = 'O'
GROUP BY r.r_name, ts.s_name, ts.TotalAccountBalance
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY TotalOrders DESC, AvgExtendedPrice DESC;
