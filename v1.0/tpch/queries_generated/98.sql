WITH supplier_stats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_orderkey) AS item_count,
        RANK() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS price_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
),
region_counts AS (
    SELECT 
        r.r_regionkey,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey
)
SELECT 
    s.s_name,
    ss.total_available,
    ss.avg_supply_cost,
    os.total_price,
    os.item_count,
    rc.nation_count
FROM supplier_stats ss
LEFT JOIN order_summary os ON ss.s_suppkey = os.o_custkey OR os.price_rank = 1
LEFT JOIN region_counts rc ON rc.nation_count > 1
WHERE ss.avg_supply_cost IS NOT NULL
AND (ss.total_available >= 100 OR ss.s_name LIKE '%Inc%')
ORDER BY ss.total_available DESC, os.total_price DESC;
