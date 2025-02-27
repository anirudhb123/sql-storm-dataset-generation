WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    ns.n_name AS nation_name,
    nr.region_name,
    cs.total_orders,
    cs.total_spent,
    ss.total_available_qty,
    ss.avg_supply_cost
FROM NationRegion nr
JOIN CustomerOrders cs ON cs.c_custkey = (
    SELECT c.c_custkey
    FROM customer c
    WHERE c.c_nationkey = nr.n_nationkey
    ORDER BY c.c_acctbal DESC
    LIMIT 1
)
FULL OUTER JOIN SupplierStats ss ON ss.s_suppkey = (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_orderkey IN (
        SELECT o.o_orderkey
        FROM orders o
        JOIN customer c ON o.o_custkey = c.c_custkey
        WHERE c.c_nationkey = nr.n_nationkey
    )
    GROUP BY ps.ps_suppkey
    ORDER BY SUM(l.l_extendedprice) DESC
    LIMIT 1
)
WHERE CS.total_spent > 1000 OR ss.total_available_qty IS NULL
ORDER BY CS.total_spent DESC, ss.avg_supply_cost ASC;
