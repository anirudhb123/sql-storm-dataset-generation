WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderstatus IN ('O', 'F')
),
CustomerSpending AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS total_parts_supplied,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING COUNT(ps.ps_partkey) > 5
),
TopRegions AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(n.n_nationkey) AS total_nations
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
    HAVING COUNT(n.n_nationkey) > 1
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    cs.c_name,
    cs.total_spent,
    sp.s_name,
    sp.total_parts_supplied,
    sp.avg_supply_cost,
    tr.r_name,
    tr.total_nations
FROM RankedOrders ro
JOIN CustomerSpending cs ON ro.o_orderkey % 100 = cs.c_custkey % 100
JOIN SupplierPerformance sp ON ro.o_orderkey % 100 = sp.s_suppkey % 100
JOIN TopRegions tr ON cs.c_custkey % 100 = tr.r_regionkey % 100
WHERE ro.order_rank <= 10 
ORDER BY ro.o_orderdate DESC, cs.total_spent DESC;
