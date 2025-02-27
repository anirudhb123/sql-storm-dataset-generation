WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_nationkey,
        1 AS level
    FROM customer c
    WHERE c.c_acctbal > 1000
    UNION ALL
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_nationkey,
        ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_acctbal > 500
),
NationSupply AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COALESCE(SUM(ps.ps_availqty), 0) AS total_avail_qty,
        COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_supply_value
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_nationkey, n.n_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank,
        COUNT(*) OVER (PARTITION BY o.o_orderstatus) AS total_orders
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
)
SELECT 
    ch.c_name,
    ch.level,
    ns.n_name AS nation_name,
    ns.total_avail_qty,
    ns.total_supply_value,
    os.price_rank,
    os.total_orders
FROM CustomerHierarchy ch
LEFT JOIN NationSupply ns ON ch.c_nationkey = ns.n_nationkey
LEFT JOIN OrderSummary os ON os.o_totalprice > 1000
WHERE ns.total_avail_qty > 100
ORDER BY ch.level, ns.total_supply_value DESC
LIMIT 100;
