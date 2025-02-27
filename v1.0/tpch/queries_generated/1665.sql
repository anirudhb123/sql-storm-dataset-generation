WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
),
SupplierStats AS (
    SELECT 
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_nationkey
),
CustomerSpending AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    r.o_orderdate,
    COALESCE(cs.total_spent, 0) AS customer_total_spent,
    ss.part_count AS supplier_part_count,
    ss.total_supply_cost,
    (ss.total_supply_cost / NULLIF(cs.total_spent, 0)) AS supply_cost_to_spending_ratio
FROM RankedOrders r
LEFT JOIN CustomerSpending cs ON r.o_orderkey = cs.c_custkey
LEFT JOIN SupplierStats ss ON ss.s_nationkey = (
    SELECT n.n_nationkey 
    FROM nation n 
    JOIN supplier s ON n.n_nationkey = s.s_nationkey 
    WHERE s.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = r.o_orderkey)
        LIMIT 1
    )
)
WHERE r.rnk <= 10
ORDER BY r.o_orderdate DESC;
