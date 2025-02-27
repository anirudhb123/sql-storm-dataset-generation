WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, p.p_partkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > (
        SELECT AVG(o2.o_totalprice) 
        FROM orders o2 
        WHERE o2.o_orderstatus IN ('O', 'F')
    )
),
SupplierOrderStats AS (
    SELECT 
        l.l_suppkey,
        COUNT(DISTINCT o.o_orderkey) AS OrderCount,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS AvgOrderValue,
        MAX(o.o_orderdate) AS LastOrderDate
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY l.l_suppkey
)
SELECT 
    ns.n_name, 
    COALESCE(AVG(s.TotalCost), 0) AS AvgSupplierCost,
    COALESCE(MAX(c.TotalSpent), 0) AS MaxCustomerSpend,
    ss.OrderCount,
    ss.AvgOrderValue,
    ss.LastOrderDate
FROM nation ns
LEFT JOIN RankedSuppliers s ON ns.n_nationkey = (SELECT n.n_nationkey FROM supplier s2 JOIN nation n ON s2.s_nationkey = n.n_nationkey WHERE s2.s_suppkey = s.s_suppkey GROUP BY n.n_nationkey)
LEFT JOIN HighValueCustomers c ON c.c_custkey IN (
    SELECT DISTINCT o.o_custkey 
    FROM orders o 
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
    WHERE l.l_suppkey IN (SELECT s.s_suppkey FROM RankedSuppliers s WHERE s.rn = 1)
)
LEFT JOIN SupplierOrderStats ss ON ss.l_suppkey = s.s_suppkey
GROUP BY ns.n_name, ss.OrderCount, ss.AvgOrderValue, ss.LastOrderDate
ORDER BY ns.n_name;
