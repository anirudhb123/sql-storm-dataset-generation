WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS line_item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY o.o_orderkey
),
RegionSummary AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(cs.total_supply_cost) AS total_supply_cost
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN SupplierStats cs ON cs.s_suppkey IN (SELECT DISTINCT s.s_suppkey
                                                  FROM supplier s
                                                  WHERE s.s_nationkey = n.n_nationkey)
    GROUP BY r.r_name
)
SELECT 
    rs.r_name,
    rs.nation_count,
    rs.total_supply_cost,
    os.total_revenue,
    os.line_item_count
FROM RegionSummary rs
JOIN OrderStats os ON rs.nation_count > 0
ORDER BY rs.total_supply_cost DESC, os.total_revenue DESC
LIMIT 10;