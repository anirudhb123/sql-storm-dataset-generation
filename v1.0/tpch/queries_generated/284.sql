WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2022-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
NationSummary AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS num_suppliers
    FROM nation n
    LEFT OUTER JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
)
SELECT 
    n.n_name,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    COALESCE(RAO.o_orderkey, 'No Orders') AS orderkey,
    HVC.total_spent
FROM NationSummary n
LEFT JOIN SupplierStats s ON n.num_suppliers = s.total_available
LEFT JOIN RankedOrders RAO ON RAO.price_rank = 1
LEFT JOIN HighValueCustomers HVC ON HVC.c_custkey = COALESCE(s.s_suppkey, -1)
WHERE (HVC.total_spent IS NOT NULL OR s.avg_supply_cost IS NOT NULL)
ORDER BY n.n_name, supplier_name;
