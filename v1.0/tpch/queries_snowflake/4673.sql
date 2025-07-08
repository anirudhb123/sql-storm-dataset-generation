WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) as OrderRank
    FROM orders o
),
SupplierExpenses AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalExpense
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
HighValueCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
RecentLineItems AS (
    SELECT 
        l.l_orderkey,
        COUNT(*) AS LineItemCount,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalLineItemValue
    FROM lineitem l
    WHERE l.l_shipdate >= cast('1998-10-01' as date) - INTERVAL '30 days'
    GROUP BY l.l_orderkey
)
SELECT 
    r.o_orderkey,
    COALESCE(hc.c_name, 'Unknown Customer') AS CustomerName,
    r.o_orderdate,
    r.o_totalprice,
    COALESCE(se.TotalExpense, 0.00) AS SupplierExpense,
    rl.LineItemCount,
    rl.TotalLineItemValue,
    r.OrderRank
FROM RankedOrders r
LEFT JOIN HighValueCustomers hc ON r.o_orderkey = hc.c_custkey
LEFT JOIN SupplierExpenses se ON se.s_suppkey = (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_orderkey = r.o_orderkey
    LIMIT 1
)
LEFT JOIN RecentLineItems rl ON r.o_orderkey = rl.l_orderkey
WHERE r.o_totalprice > 100 AND r.OrderRank <= 10
ORDER BY r.o_orderdate DESC;