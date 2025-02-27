
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS spend_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
),
RegionNationStats AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT 
    r.r_name,
    ns.nation_count,
    ns.supplier_count,
    COALESCE(ss.total_avail_qty, 0) AS total_avail_qty,
    COALESCE(cs.total_orders, 0) AS total_orders,
    COALESCE(cs.total_spent, 0) AS total_spent
FROM RegionNationStats ns
JOIN region r ON ns.r_regionkey = r.r_regionkey
FULL OUTER JOIN SupplierStats ss ON ss.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps 
    WHERE ps.ps_availqty > (
        SELECT AVG(ps_inner.ps_availqty) 
        FROM partsupp ps_inner
    )
)
FULL OUTER JOIN CustomerOrderStats cs ON cs.c_custkey IN (
    SELECT c.c_custkey
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
    AND c.c_acctbal > (
        SELECT AVG(c_inner.c_acctbal) 
        FROM customer c_inner
    )
)
WHERE (ns.nation_count > 2 OR ns.supplier_count > 5)
AND r.r_name IS NOT NULL
ORDER BY r.r_name, total_spent DESC
LIMIT 100;
